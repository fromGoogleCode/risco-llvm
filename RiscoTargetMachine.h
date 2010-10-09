//===-- RiscoTargetMachine.h - Define TargetMachine for Risco -00--*- C++ -*-===//
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

#include "RiscoSubtarget.h"
#include "RiscoInstrInfo.h"
#include "RiscoISelLowering.h"
#include "RiscoSelectionDAGInfo.h"

#include "llvm/Target/TargetData.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetFrameInfo.h"


namespace llvm {
  class formatted_raw_ostream;
  
  class RiscoTargetMachine : public LLVMTargetMachine {
    RiscoSubtarget       Subtarget;
    const TargetData    DataLayout; // Calculates type size & alignment
    RiscoInstrInfo       InstrInfo;
    TargetFrameInfo     FrameInfo;
    RiscoTargetLowering  TLInfo;
    RiscoSelectionDAGInfo TSInfo;

  public:
    RiscoTargetMachine(const Target &T, const std::string &TT);
    
    virtual const RiscoInstrInfo   *getInstrInfo()     const
    {
        return &InstrInfo;
    }

    virtual const TargetFrameInfo *getFrameInfo()     const 
    {
      return &FrameInfo;
    }

    virtual const RiscoSubtarget   *getSubtargetImpl() const
    {
      return &Subtarget;
    }

    virtual const TargetData      *getTargetData()    const 
    {
      return &DataLayout;
    }

    virtual const RiscoRegisterInfo *getRegisterInfo()  const
    {
      return &InstrInfo.getRegisterInfo();
    }

    virtual const RiscoTargetLowering *getTargetLowering() const
    {
      return &TLInfo;
    }

    virtual const RiscoSelectionDAGInfo* getSelectionDAGInfo() const
    {
      return &TSInfo;
    }

    // Pass Pipeline Configuration
    virtual bool addInstSelector(PassManagerBase &PM,
                                 CodeGenOpt::Level OptLevel);
    virtual bool addPreEmitPass(PassManagerBase &PM,
                                CodeGenOpt::Level OptLevel);
  };

/// RiscoSimTargetMachine - Risco simulator subtarget
///
class RiscoSimTargetMachine : public RiscoTargetMachine {
public:
  RiscoSimTargetMachine(const Target &T, const std::string &TT);
};

} // End llvm namespace

#endif
