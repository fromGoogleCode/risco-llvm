//===- RiscoSubtarget.cpp - RISCO Subtarget Information -------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the RISCO specific subclass of TargetSubtarget.
//
//===----------------------------------------------------------------------===//

#include "RiscoSubtarget.h"
#include "RiscoGenSubtarget.inc"
using namespace llvm;


RiscoSubtarget::RiscoSubtarget(const std::string &TT, const std::string &FS) {
  // Parse features string.
  ParseSubtargetFeatures(FS, "simulator");
}
