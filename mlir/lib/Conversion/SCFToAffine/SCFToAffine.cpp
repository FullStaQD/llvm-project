//===- SCFToAffine.cpp - SCF to Affine conversion -------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements a pass to raise scf ops to affine ops.
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/SCFToAffine/SCFToAffine.h"
#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/IR/AffineExpr.h"
#include "mlir/IR/AffineMap.h"
#include "mlir/IR/Value.h"
#include "mlir/Interfaces/DataLayoutInterfaces.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "llvm/ADT/SmallVector.h"

namespace mlir {
#define GEN_PASS_DEF_RAISESCFTOAFFINEPASS
#include "mlir/Conversion/Passes.h.inc"
} // namespace mlir

using namespace mlir;

namespace {

//===----------------------------------------------------------------------===//
// SCFToAffinePass
//===----------------------------------------------------------------------===//

struct SCFToAffinePass
    : public impl::RaiseSCFToAffinePassBase<SCFToAffinePass> {
  void runOnOperation() override;
};

//===----------------------------------------------------------------------===//
// ForOpRewrite
//===----------------------------------------------------------------------===//

/// Raise an `scf.for` to an equivalent `affine.for` if lb, ub and step satisfy
/// certain constraints making this possible.
struct ForOpRewrite : public OpRewritePattern<scf::ForOp> {
  using OpRewritePattern<scf::ForOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(scf::ForOp op,
                                PatternRewriter &rewriter) const override;

private:
  /// Definitively decide whether we are going to raise or not.
  ///
  /// An `scf.for` can trivially be raised if lb, ub are dimensions and step is
  /// a constant. With some more work one can raise under relaxed constraints as
  /// expressed by this function.
  bool canRaiseToAffine(scf::ForOp op) const;

  /// Cast lb, ub, step and the induction variable of an integer-typed `op` to
  /// `index`, in place. The bound and step casts are placed at the top level of
  /// the affine scope so they are valid affine symbols; the induction variable
  /// is cast back to its original type at the start of the body so the body is
  /// left unchanged. Assumes `canRaiseToAffine(op) == true`.
  void castBoundsToIndex(scf::ForOp op, PatternRewriter &rewriter) const;

  /// Returns an equivalent `affine.for` skeleton and the *old* induction
  /// variable for use by the body that is inlined later. The affine loop body
  /// is left empty except for an operation computing the old induction variable
  /// from the new one *iff* it differs from the new one.
  ///
  /// Assumes `canRaiseToAffine(op) == true` and index casts were performed (if
  /// necessary).
  ///
  /// There are two cases:
  ///
  /// 1. step is constant
  /// 2. step is dynamic (not constant)
  ///
  /// In case (1) and if lb, ub are (valid) dimensions `scf.for` is trivially
  /// raised (leaving lb, ub, iv as is). If lb is an `affine.max` we "inline" it
  /// into the loop's lower bound map. Similarly if ub is an `affine.min`.
  ///
  /// In case (2) we *normalize* the loop to run from 0 with step 1: the new
  /// upper bound is `ceil((ub - lb) / step)` and the original induction
  /// variable is recovered in the body as `lb + step * new_iv`. Here we require
  /// lb to be a dimension; ub may still be an `affine.min`, which is rescaled
  /// accordingly.
  std::pair<affine::AffineForOp, Value>
  createAffineFor(scf::ForOp op, PatternRewriter &rewriter) const;

  std::pair<affine::AffineForOp, Value>
  createAffineForWithConstantStep(scf::ForOp op, int64_t step,
                                  PatternRewriter &rewriter) const;

  std::pair<affine::AffineForOp, Value>
  createAffineForWithDynamicStep(scf::ForOp op,
                                 PatternRewriter &rewriter) const;
};

static bool areValidAffineMapOperands(AffineMap map, ValueRange operands,
                                      Region *scope) {
  assert(map.getNumInputs() == operands.size() &&
         "expected one operand per affine map input");
  return llvm::all_of(
             operands.take_front(map.getNumDims()),
             [&](Value value) { return affine::isValidDim(value, scope); }) &&
         llvm::all_of(operands.drop_front(map.getNumDims()), [&](Value value) {
           return affine::isValidSymbol(value, scope);
         });
}

bool indexBoundsRaisable(scf::ForOp op) {
  Value lb = op.getLowerBound();
  Value ub = op.getUpperBound();
  IntegerAttr constAttr;
  Region *scope = affine::getAffineScope(op);
  if (!scope)
    return false;

  // The asymmetry between lb and ub comes from the fact that the step
  // normalization (for non-constant (dynamic) steps) does not work with
  // multiple *lower* bounds (max).
  auto lbMaxOp = lb.getDefiningOp<affine::AffineMaxOp>();
  bool lbOK = affine::isValidDim(lb, scope) ||
              (lbMaxOp && matchPattern(op.getStep(), m_Constant(&constAttr)) &&
               areValidAffineMapOperands(lbMaxOp.getAffineMap(),
                                         lbMaxOp->getOperands(), scope));
  auto ubMinOp = ub.getDefiningOp<affine::AffineMinOp>();
  bool ubOK =
      affine::isValidDim(ub, scope) ||
      (ubMinOp && areValidAffineMapOperands(ubMinOp.getAffineMap(),
                                            ubMinOp->getOperands(), scope));
  bool stepOK = affine::isValidSymbol(op.getStep(), scope);

  return lbOK && ubOK && stepOK;
}

/// If `value` is the result of an `arith.index_cast` / `arith.index_castui`
/// whose input is of `index` type, return that input; otherwise return
/// `value` unchanged.
static Value lookThroughIndexCastToIndex(Value value) {
  Operation *defOp = value.getDefiningOp();
  if (!isa_and_present<arith::IndexCastOp, arith::IndexCastUIOp>(defOp))
    return value;
  Value in = defOp->getOperand(0);
  if (!in.getType().isIndex())
    return value;
  return in;
}

/// Decide whether an integer-typed loop can be raised by first casting its
/// bounds (lb, ub, step) to `index`. Requires the cast to be lossless under
/// affine's *signed* `index` interpretation, and every bound to be available
/// as a legal affine symbol/dimension at the loop's location.
///
/// A bound is raisable if it falls into one of the following cases:
///   1. It is an `arith.index_cast`/`index_castui` of an `index`-typed value
///      that is a legal affine dimension or symbol in the loop's parent region.
///      The cast input is reused directly, so no new cast is needed.
///   2. It is a (foldable) constant. An equivalent `index` constant is
///      materialized in the loop's parent region, which is a legal affine
///      symbol everywhere.
///   3. It is a genuine integer value defined at the top level of the affine
///      scope, so a cast to `index` can be hoisted there and become a valid
///      affine symbol.
static bool intBoundsRaisable(scf::ForOp op, IntegerType intType) {
  uint64_t indexWidth = DataLayout::closest(op)
                            .getTypeSizeInBits(IndexType::get(op.getContext()))
                            .getFixedValue();
  // Lossless under signed index: sign-extend needs width <= indexWidth;
  // zero-extend (unsigned) needs a spare sign bit, i.e. width < indexWidth.
  uint64_t requiredWidth = intType.getWidth() + (op.getUnsignedCmp() ? 1 : 0);
  if (requiredWidth > indexWidth)
    return false;

  Region *scope = affine::getAffineScope(op);
  if (scope == nullptr)
    return false;

  Region *parentRegion = op->getParentRegion();
  IntegerAttr stepConstAttr;
  bool constStep = matchPattern(op.getStep(), m_Constant(&stepConstAttr));

  auto boundRaisable = [&](Value bound) {
    // Case 1: bound is an index in disguise: We can properly check for
    // dim/symbol validity.
    if (Value underlying = lookThroughIndexCastToIndex(bound);
        underlying != bound) {
      return affine::isValidDim(underlying, parentRegion) ||
             affine::isValidSymbol(underlying, parentRegion);
    }

    // Case 2: bound is a constant and can be replaced with an index constant.
    Attribute cstAttr;
    if (matchPattern(bound, m_Constant(&cstAttr)))
      return true;

    // Case 3: a genuine non-index integer value needs a hoisted cast at the
    // affine scope, so must be defined at the top level.
    return affine::isTopLevelValue(bound, scope);
  };

  // A lower/upper bound that -- once looked through any index-cast -- is an
  // `affine.max`/`affine.min` with legal map operands is also raisable,
  // mirroring `indexBoundsRaisable`. A max lower bound additionally requires
  // a constant step; see the comment on `indexBoundsRaisable` for why.
  auto lbRaisable = [&](Value bound) {
    if (boundRaisable(bound))
      return true;
    auto maxOp =
        lookThroughIndexCastToIndex(bound).getDefiningOp<affine::AffineMaxOp>();
    return maxOp && constStep &&
           areValidAffineMapOperands(maxOp.getAffineMap(), maxOp->getOperands(),
                                     parentRegion);
  };
  auto ubRaisable = [&](Value bound) {
    if (boundRaisable(bound))
      return true;
    auto minOp =
        lookThroughIndexCastToIndex(bound).getDefiningOp<affine::AffineMinOp>();
    return minOp &&
           areValidAffineMapOperands(minOp.getAffineMap(), minOp->getOperands(),
                                     parentRegion);
  };

  return lbRaisable(op.getLowerBound()) && ubRaisable(op.getUpperBound()) &&
         boundRaisable(op.getStep());
}

[[nodiscard]] bool ForOpRewrite::canRaiseToAffine(scf::ForOp op) const {
  Type type = op.getInductionVar().getType();
  if (isa<IndexType>(type))
    return indexBoundsRaisable(op);
  if (auto intType = dyn_cast<IntegerType>(type))
    return intBoundsRaisable(op, intType);
  return false;
}

LogicalResult ForOpRewrite::matchAndRewrite(scf::ForOp op,
                                            PatternRewriter &rewriter) const {
  if (!canRaiseToAffine(op)) {
    return rewriter.notifyMatchFailure(op, "cannot raise scf op to affine");
  }

  if (!isa<IndexType>(op.getInductionVar().getType()))
    castBoundsToIndex(op, rewriter);

  auto [affineFor, oldIV] = createAffineFor(op, rewriter);
  Block *affineBody = affineFor.getBody();

  if (affineBody->mightHaveTerminator()) {
    // No unregistered ops in the body, so this is definitive.
    Operation *terminator = affineBody->getTerminator();
    assert(isa<affine::AffineYieldOp>(terminator) &&
           "expected affine.yield if there *might* be terminator");
    rewriter.eraseOp(terminator);
  }

  SmallVector<Value> argValues;
  argValues.push_back(oldIV);
  llvm::append_range(argValues, affineFor.getRegionIterArgs());
  rewriter.inlineBlockBefore(op.getBody(), affineBody, affineBody->end(),
                             argValues);

  auto scfYieldOp = cast<scf::YieldOp>(affineBody->getTerminator());
  rewriter.setInsertionPointToEnd(affineBody);
  rewriter.replaceOpWithNewOp<affine::AffineYieldOp>(scfYieldOp,
                                                     scfYieldOp->getOperands());

  rewriter.replaceOp(op, affineFor);
  return success();
}

std::pair<affine::AffineForOp, Value>
ForOpRewrite::createAffineFor(scf::ForOp op, PatternRewriter &rewriter) const {
  IntegerAttr constAttr;
  if (matchPattern(op.getStep(), m_Constant(&constAttr))) {
    int64_t step = constAttr.getInt();
    assert(step > 0 && "scf.for has positive step");
    return createAffineForWithConstantStep(op, step, rewriter);
  }
  return createAffineForWithDynamicStep(op, rewriter);
}

std::pair<affine::AffineForOp, Value>
ForOpRewrite::createAffineForWithConstantStep(scf::ForOp op, int64_t step,
                                              PatternRewriter &rewriter) const {
  Value lb = op.getLowerBound();
  Value ub = op.getUpperBound();

  auto lbOperands = ValueRange(lb);
  auto ubOperands = ValueRange(ub);

  auto lbMap = AffineMap::getMultiDimIdentityMap(1, rewriter.getContext());
  auto ubMap = AffineMap::getMultiDimIdentityMap(1, rewriter.getContext());

  if (auto ubMinOp = ub.getDefiningOp<affine::AffineMinOp>()) {
    ubOperands = ubMinOp->getOperands();
    ubMap = ubMinOp.getAffineMap();
  }

  if (auto lbMaxOp = lb.getDefiningOp<affine::AffineMaxOp>()) {
    lbOperands = lbMaxOp->getOperands();
    lbMap = lbMaxOp.getAffineMap();
  }

  auto affineFor =
      affine::AffineForOp::create(rewriter, op.getLoc(), lbOperands, lbMap,
                                  ubOperands, ubMap, step, op.getInits());

  return {affineFor, affineFor.getInductionVar()};
}

std::pair<affine::AffineForOp, Value>
ForOpRewrite::createAffineForWithDynamicStep(scf::ForOp op,
                                             PatternRewriter &rewriter) const {
  Value lb = op.getLowerBound();
  Value ub = op.getUpperBound();
  Value step = op.getStep();

  assert(affine::isValidDim(lb) &&
         "dynamic-step lower bound must be a valid affine dim");

  AffineExpr d0 = rewriter.getAffineDimExpr(0);
  AffineExpr d1 = rewriter.getAffineDimExpr(1);
  AffineExpr s0 = rewriter.getAffineSymbolExpr(0);
  AffineMap zeroMap = rewriter.getConstantAffineMap(0);

  llvm::SmallVector<Value, 3> ubOperands = {lb, ub, step};

  // ub is transformed with (x - lb + step - 1) floorDiv step where x ranges
  // over all ub_i. lb is transformed to zero.

  AffineMap ubMap = AffineMap::get(2, 1, (d1 - d0 + s0 - 1).floorDiv(s0));

  if (auto ubMinOp = ub.getDefiningOp<affine::AffineMinOp>()) {
    AffineMap origUbMap = ubMinOp.getAffineMap();
    unsigned ubDims = origUbMap.getNumDims();
    unsigned ubSyms = origUbMap.getNumSymbols();

    AffineExpr lbDim = rewriter.getAffineDimExpr(ubDims);
    AffineExpr stepSym = rewriter.getAffineSymbolExpr(ubSyms);

    SmallVector<AffineExpr> ubExprs;
    ubExprs.reserve(origUbMap.getNumResults());
    for (AffineExpr ubI : origUbMap.getResults()) {
      ubExprs.push_back((ubI - lbDim + stepSym - 1).floorDiv(stepSym));
    }

    // Combined space: dims = [ub dims, lb]
    //                 syms = [ub syms, step]
    ubMap =
        AffineMap::get(ubDims + 1, ubSyms + 1, ubExprs, rewriter.getContext());

    // Operand order consistent with "combined space" above:
    ValueRange ubOps = ubMinOp->getOperands();
    SmallVector<Value> combined;
    combined.append(ubOps.begin(), ubOps.begin() + ubDims); // ub dims
    combined.push_back(lb);                                 // lb (single dim)
    combined.append(ubOps.begin() + ubDims, ubOps.end());   // ub syms
    combined.push_back(op.getStep());                       // step (single sym)
    ubOperands = std::move(combined);
  }

  auto affineFor = affine::AffineForOp::create(
      rewriter, op.getLoc(), {}, zeroMap, ubOperands, ubMap, 1, op.getInits());

  // old_iv = old_lb + new_iv * step
  AffineMap ivMap = AffineMap::get(2, 1, d0 + d1 * s0);

  llvm::SmallVector<Value, 3> ivOperands = {lb, affineFor.getInductionVar(),
                                            step};

  rewriter.setInsertionPointToStart(affineFor.getBody());
  auto oldIV =
      affine::AffineApplyOp::create(rewriter, op.getLoc(), ivMap, ivOperands);

  return {affineFor, oldIV};
}

void ForOpRewrite::castBoundsToIndex(scf::ForOp loop,
                                     PatternRewriter &rewriter) const {
  OpBuilder::InsertionGuard guard(rewriter);

  Value lb = loop.getLowerBound();
  Value ub = loop.getUpperBound();
  Value step = loop.getStep();
  Type originalType = step.getType();

  assert(lb.getType() == originalType && ub.getType() == originalType &&
         "expected lb, ub, and step to have the same type");

  auto createIndexCast = [&](Type out, Value in) -> Value {
    Location loc = loop.getLoc();
    if (loop.getUnsignedCmp())
      return arith::IndexCastUIOp::create(rewriter, loc, out, in);
    return arith::IndexCastOp::create(rewriter, loc, out, in);
  };

  // The affine scope, used as the insertion point for casts that must be
  // hoisted to become valid affine symbols (case 3 below).
  Region *scope = affine::getAffineScope(loop);
  Operation *anchor = scope->findAncestorOpInRegion(*loop);

  auto createIndexBound = [&](Value bound) -> Value {
    // Case 1: reuse the underlying index value directly.
    if (Value underlying = lookThroughIndexCastToIndex(bound);
        underlying != bound) {
      return underlying;
    }
    // Case 2: constant int -> constant index
    Attribute cstAttr;
    if (matchPattern(bound, m_Constant(&cstAttr))) {
      rewriter.setInsertionPoint(loop);
      return arith::ConstantOp::create(rewriter, loop.getLoc(),
                                       rewriter.getIndexType(),
                                       cast<TypedAttr>(cstAttr));
    }
    // Case 3: hoist a cast to the affine scope top level.
    rewriter.setInsertionPoint(anchor);
    return createIndexCast(rewriter.getIndexType(), bound);
  };

  Value newLb = createIndexBound(lb);
  Value newUb = createIndexBound(ub);
  Value newStep = createIndexBound(step);

  rewriter.modifyOpInPlace(loop, [&] {
    loop.setLowerBound(newLb);
    loop.setUpperBound(newUb);
    loop.setStep(newStep);

    Value originalIV = loop.getInductionVar();
    Value iv = loop.getBody()->insertArgument(
        static_cast<unsigned>(0), rewriter.getIndexType(), loop.getLoc());

    rewriter.setInsertionPointToStart(loop.getBody());
    Value castIV = createIndexCast(originalType, iv);
    rewriter.replaceAllUsesWith(originalIV, castIV);

    // Original induction var is now at index 1.
    loop.getBody()->eraseArgument(1);
  });
}

//===----------------------------------------------------------------------===//
// MinMaxOpRewrite
//===----------------------------------------------------------------------===//

static Value getRaisableIndexOperand(Value value, Operation *user,
                                     Region *scope) {

  // TODO: symbol implies dim, so dim check would suffice. double check.
  auto isValidAffineOperand = [&](Value v) {
    return affine::isValidSymbol(v, scope) || affine::isValidDim(v, scope);
  };

  if (value.getType().isIndex())
    return isValidAffineOperand(value) ? value : nullptr;

  auto intType = dyn_cast<IntegerType>(value.getType());
  if (!intType)
    return nullptr;

  uint64_t indexWidth =
      DataLayout::closest(user)
          .getTypeSizeInBits(IndexType::get(user->getContext()))
          .getFixedValue();
  // Only signed (arith.maxsi/minsi) raising is supported, so a plain
  // sign-extend suffices; no extra bit is needed as for unsigned bounds.
  // TODO: Also support unsigned
  if (intType.getWidth() > indexWidth)
    return nullptr;

  if (Value underlying = lookThroughIndexCastToIndex(value);
      underlying != value) {
    return isValidAffineOperand(underlying) ? underlying : nullptr;
  }

  return affine::isTopLevelValueOrAbove(value, scope) ? value : nullptr;
}

static Value materializeIndexOperand(Value value, Operation *user,
                                     PatternRewriter &rewriter) {
  if (value.getType().isIndex())
    return value;

  Operation *castPoint = value.getParentRegion()->findAncestorOpInRegion(*user);
  OpBuilder::InsertionGuard guard(rewriter);
  rewriter.setInsertionPoint(castPoint);
  return arith::IndexCastOp::create(rewriter, castPoint->getLoc(),
                                    rewriter.getIndexType(), value);
}

/// Raise a binary `arith.maxsi`/`arith.minsi` to `affine.max`/`affine.min`
/// when both operands are (or can losslessly be cast to) legal affine
/// dims/symbols. This is intentionally *not* done for `arith.maxui`/
/// `arith.minui`: `affine.max`/`affine.min` evaluate their affine
/// expressions as signed integers, so raising an unsigned comparison would
/// change semantics for operands that are negative as signed values.
///
/// Raising these standalone -- not just when they are already an `scf.for`
/// bound -- matters for non-rectangular loop nests: a bound that depends on
/// an enclosing loop's induction variable only becomes raisable as an
/// `scf.for` bound once it is an actual `affine.max`/`affine.min` (see
/// `indexBoundsRaisable` / `intBoundsRaisable` above, which special-case
/// those op kinds).
template <typename ArithOp, typename AffineOp>
struct MinMaxOpRewrite : public OpRewritePattern<ArithOp> {
  using OpRewritePattern<ArithOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(ArithOp op,
                                PatternRewriter &rewriter) const override {
    Region *scope = affine::getAffineScope(op);
    if (!scope)
      return rewriter.notifyMatchFailure(op, "no enclosing affine scope");

    Value lhs = getRaisableIndexOperand(op.getLhs(), op, scope);
    if (!lhs) {
      return rewriter.notifyMatchFailure(
          op, "lhs is not raisable to an affine dim/symbol");
    }
    Value rhs = getRaisableIndexOperand(op.getRhs(), op, scope);
    if (!rhs) {
      return rewriter.notifyMatchFailure(
          op, "rhs is not raisable to an affine dim/symbol");
    }

    // From here on the rewrite is known to succeed, so the operands may be
    // cast to `index`. Categorize each of them as a dim or a symbol,
    // preferring symbol (a strict superset of what's legal as a dim).
    // TODO: Or should this be left to canonicalization?
    SmallVector<Value> dimOperands, symOperands;
    SmallVector<AffineExpr> exprs;
    for (Value operand : {lhs, rhs}) {
      Value v = materializeIndexOperand(operand, op, rewriter);
      if (affine::isValidSymbol(v, scope)) {
        exprs.push_back(rewriter.getAffineSymbolExpr(symOperands.size()));
        symOperands.push_back(v);
      } else {
        assert(affine::isValidDim(v, scope) &&
               "getRaisableIndexOperand accepted an illegal affine operand");
        exprs.push_back(rewriter.getAffineDimExpr(dimOperands.size()));
        dimOperands.push_back(v);
      }
    }

    AffineMap map = AffineMap::get(dimOperands.size(), symOperands.size(),
                                   exprs, rewriter.getContext());
    SmallVector<Value> operands = dimOperands;
    llvm::append_range(operands, symOperands);

    Value raised = AffineOp::create(rewriter, op.getLoc(), map, operands);

    Type origType = op.getResult().getType();
    if (!origType.isIndex())
      raised =
          arith::IndexCastOp::create(rewriter, op.getLoc(), origType, raised);

    rewriter.replaceOp(op, raised);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Pass implementation
//===----------------------------------------------------------------------===//

void SCFToAffinePass::runOnOperation() {
  MLIRContext &ctx = getContext();
  RewritePatternSet patterns(&ctx);
  populateSCFToAffineConversionPatterns(patterns);

  if (failed(applyPatternsGreedily(getOperation(), std::move(patterns))))
    signalPassFailure();
}

} // namespace

//===----------------------------------------------------------------------===//
// API
//===----------------------------------------------------------------------===//

void mlir::populateSCFToAffineConversionPatterns(RewritePatternSet &patterns) {
  patterns.add<ForOpRewrite>(patterns.getContext());
  patterns.add<MinMaxOpRewrite<arith::MaxSIOp, affine::AffineMaxOp>,
               MinMaxOpRewrite<arith::MinSIOp, affine::AffineMinOp>>(
      patterns.getContext());
}
