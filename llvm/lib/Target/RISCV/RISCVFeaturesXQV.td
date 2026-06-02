//===-- RISCVFeaturesXQV.td - RISC-V QV Features and Extensions --*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//  This file contains definitions for the RISC-V QV extension features.
//
//===----------------------------------------------------------------------===//

def FeatureVendorXQV
    : RISCVExperimentalExtension<0, 1, "QV Quantum Extension (HiSEP-Q 2.0)",
                                [FeatureStdExtV]>;

def HasVendorXQV
    : Predicate<"Subtarget->hasVendorXQV()">,
      AssemblerPredicate<(all_of FeatureVendorXQV),
                         "'XQV' (QV Quantum Extension)">;
