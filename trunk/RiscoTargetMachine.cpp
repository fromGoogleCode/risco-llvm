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

#include "RiscoMCAsmInfo.h"
#include "RiscoTargetMachine.h"
#include "Risco.h"
#include "llvm/PassManager.h"
#include "llvm/Target/TargetRegistry.h"
using namespace llvm;

extern "C" void LLVMInitializeRiscoTarget() {
  // Register the target.
  RegisterTargetMachine<RiscoV8TargetMachine> X(TheRiscoTarget);
  RegisterTargetMachine<RiscoV9TargetMachine> Y(TheRiscoV9Target);

  RegisterAsmInfo<RiscoELFMCAsmInfo> A(TheRiscoTarget);
  RegisterAsmInfo<RiscoELFMCAsmInfo> B(TheRiscoV9Target);

}

/// RiscoTargetMachine ctor - Create an ILP32 architecture model
///
RiscoTargetMachine::RiscoTargetMachine(const Target &T, const std::string &TT,
                                       const std::string &FS, bool is64bit)
  : LLVMTargetMachine(T, TT),
    Subtarget(TT, FS, is64bit),
    DataLayout(Subtarget.getDataLayout()),
     TLInfo(*this), TSInfo(*this), InstrInfo(Subtarget),
    FrameInfo(TargetFrameInfo::StackGrowsDown, 8, 0) {
}

bool RiscoTargetMachine::addInstSelector(PassManagerBase &PM,
                                         CodeGenOpt::Level OptLevel) {
  PM.add(createRiscoISelDag(*this));
  return false;
}

/// addPreEmitPass - This pass may be implemented by targets that want to run
/// passes immediately before machine code is emitted.  This should return
/// true if -print-machineinstrs should print out the code after the passes.
bool RiscoTargetMachine::addPreEmitPass(PassManagerBase &PM,
                                        CodeGenOpt::Level OptLevel){
  PM.add(createRiscoFPMoverPass(*this));
  PM.add(createRiscoDelaySlotFillerPass(*this));
  return true;
}

RiscoV8TargetMachine::RiscoV8TargetMachine(const Target &T,
                                           const std::string &TT, 
                                           const std::string &FS)
  : RiscoTargetMachine(T, TT, FS, false) {
}

RiscoV9TargetMachine::RiscoV9TargetMachine(const Target &T,
                                           const std::string &TT, 
                                           const std::string &FS)
  : RiscoTargetMachine(T, TT, FS, true) {
}
