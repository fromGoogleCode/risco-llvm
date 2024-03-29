//===-- RiscoTargetInfo.cpp - Risco Target Implementation -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "Risco.h"
#include "llvm/Module.h"
#include "llvm/Target/TargetRegistry.h"
using namespace llvm;

Target llvm::TheRiscoTarget;

extern "C" void LLVMInitializeRiscoTargetInfo() {
  RegisterTarget<Triple::sparc> X(TheRiscoTarget, "risco", "Risco");
}
