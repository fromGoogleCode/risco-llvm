//===-- RiscoTargetMachine.h - Define TargetMachine for Risco ---*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the Risco specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#ifndef RISCOTARGETMACHINE_H
#define RISCOTARGETMACHINE_H

#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetData.h"
#include "llvm/Target/TargetFrameInfo.h"
#include "RiscoInstrInfo.h"
#include "RiscoSubtarget.h"
#include "RiscoISelLowering.h"
#include "RiscoSelectionDAGInfo.h"


namespace llvm {

  class RiscoTargetMachine : public LLVMTargetMachine {
    RiscoSubtarget Subtarget;
    const TargetData DataLayout; // Calculates type size & alignment
    RiscoTargetLowering TLInfo;
    RiscoSelectionDAGInfo TSInfo;
    RiscoInstrInfo InstrInfo;
    TargetFrameInfo FrameInfo;

  public:
    RiscoTargetMachine(const Target &T, const std::string &TT);

    virtual const RiscoInstrInfo *getInstrInfo() const {
      return &InstrInfo;
    }

    virtual const TargetFrameInfo *getFrameInfo() const {
      return &FrameInfo;
    }

    virtual const RiscoSubtarget *getSubtargetImpl() const {
      return &Subtarget;
    }

    virtual const RiscoRegisterInfo *getRegisterInfo() const {
      return &InstrInfo.getRegisterInfo();
    }

    virtual const RiscoTargetLowering* getTargetLowering() const {
      return &TLInfo;
    }

    virtual const RiscoSelectionDAGInfo* getSelectionDAGInfo() const {
      return &TSInfo;
    }

    virtual const TargetData *getTargetData() const {
      return &DataLayout;
    }

    // Pass Pipeline Configuration
    virtual bool addInstSelector(PassManagerBase &PM, CodeGenOpt::Level OptLevel);
    virtual bool addPreEmitPass(PassManagerBase &PM, CodeGenOpt::Level OptLevel);
  };

  class RiscoSimulatorTargetMachine : public RiscoTargetMachine {
  public:
    RiscoSimulatorTargetMachine(const Target &T, const std::string &TT);
  };


} // end namespace llvm

#endif
