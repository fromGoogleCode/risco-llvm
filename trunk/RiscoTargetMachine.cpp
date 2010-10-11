//===-- RiscoTargetMachine.cpp - Define TargetMachine for Risco -----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//
//===----------------------------------------------------------------------===//

#include "Risco.h"
#include "RiscoMCAsmInfo.h"
#include "RiscoTargetMachine.h"

#include "llvm/PassManager.h"
#include "llvm/Target/TargetRegistry.h"
using namespace llvm;


extern "C" void LLVMInitializeRiscoTarget()
{
  // Register the target.
  RegisterTargetMachine<RiscoSimulatorTargetMachine> X(TheRiscoTarget);
  RegisterAsmInfo<RiscoMCAsmInfo> X(TheRiscoTarget);
}


RiscoTargetMachine::RiscoTargetMachine(const Target &T, const std::string &TT)
    : LLVMTargetMachine(T, TT),
      Subtarget(TT),
      DataLayout("e-p:32:32:32-i32:32:32"),
      TLInfo(*this), TSInfo(*this),
      InstrInfo(Subtarget),
      FrameInfo(TargetFrameInfo::StackGrowsDown, 4, 0)
{ }


bool RiscoTargetMachine::addInstSelector(PassManagerBase &PM, CodeGenOpt::Level OptLevel)
{
  PM.add(createRiscoISelDag(*this));
  return false;
}


bool RiscoTargetMachine::addPreEmitPass(PassManagerBase &PM,
        CodeGenOpt::Level OptLevel)
{
  //PM.add(createRiscoFPMoverPass(*this));
  //PM.add(createRiscoDelaySlotFillerPass(*this));
  //return true;
  return false;
}


RiscoSimulatorTargetMachine::RiscoSimulatorTargetMachine(
        const Target &T,
        const std::string &TT)
: RiscoTargetMachine(T, TT)
{ }
