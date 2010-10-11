//===-- RiscoSelectionDAGInfo.cpp - Risco SelectionDAG Info ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the RiscoSelectionDAGInfo class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "sparc-selectiondag-info"
#include "RiscoTargetMachine.h"
using namespace llvm;

RiscoSelectionDAGInfo::RiscoSelectionDAGInfo(const RiscoTargetMachine &TM)
  : TargetSelectionDAGInfo(TM) {
}

RiscoSelectionDAGInfo::~RiscoSelectionDAGInfo() {
}
