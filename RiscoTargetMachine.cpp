//===-- RiscoTargetMachine.cpp - Define TargetMachine for Risco -------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Implements the info about Risco target spec.
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
  RegisterTargetMachine<RiscoTargetMachine> X(TheRiscoTarget);
  RegisterTargetMachine<RiscoSimTargetMachine> Y(TheRiscoSimTarget);
  RegisterAsmInfo<RiscoMCAsmInfo> A(TheRiscoTarget);
  RegisterAsmInfo<RiscoMCAsmInfo> B(TheRiscoSimTarget);
}


// DataLayout --> Little-endian, 32-bit pointer/ABI/alignment
// The stack is always 8 byte aligned
// On function prologue, the stack is created by decrementing
// its pointer. Once decremented, all references are done with positive
// offset from the stack/frame pointer
RiscoTargetMachine::
RiscoTargetMachine(const Target &T, const std::string &TT)
  : LLVMTargetMachine(T, TT),
    Subtarget(TT),
    DataLayout("e-p:32:32-i32:32"),
    InstrInfo(*this),
    FrameInfo(TargetFrameInfo::StackGrowsDown, 32, 0),
    TLInfo(*this), TSInfo(*this)
{}


RiscoSimTargetMachine::
RiscoSimTargetMachine(const Target &T, const std::string &TT,
                     const std::string &FS) :
  RiscoTargetMachine(T, TT, FS, true)
{}


// Install an instruction selector pass using 
// the ISelDag to gen Risco code.
bool RiscoTargetMachine::
addInstSelector(PassManagerBase &PM, CodeGenOpt::Level OptLevel) 
{
  PM.add(createRiscoISelDag(*this));
  return false;
}


// Implemented by targets that want to run passes immediately before 
// machine code is emitted. return true if -print-machineinstrs should 
// print out the code after the passes.
bool RiscoTargetMachine::
addPreEmitPass(PassManagerBase &PM, CodeGenOpt::Level OptLevel) 
{
  //PM.add(createRiscoDelaySlotFillerPass(*this));
  return true;
}
