//===-- RiscoSelectionDAGInfo.h - Risco SelectionDAG Info -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the Risco subclass for TargetSelectionDAGInfo.
//
//===----------------------------------------------------------------------===//

#ifndef RISCOSELECTIONDAGINFO_H
#define RISCOSELECTIONDAGINFO_H

#include "llvm/Target/TargetSelectionDAGInfo.h"

namespace llvm {

class RiscoTargetMachine;

class RiscoSelectionDAGInfo : public TargetSelectionDAGInfo {
public:
  explicit RiscoSelectionDAGInfo(const RiscoTargetMachine &TM);
  ~RiscoSelectionDAGInfo();
};

}

#endif
