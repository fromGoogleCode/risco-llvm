//===- RiscoRegisterInfo.cpp - RISCO Register Information -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the RISCO implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#include "Risco.h"
#include "RiscoRegisterInfo.h"
#include "RiscoSubtarget.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineLocation.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/Type.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/STLExtras.h"
using namespace llvm;


RiscoRegisterInfo::RiscoRegisterInfo(RiscoSubtarget &st, const TargetInstrInfo &tii)
      : RiscoGenRegisterInfo(Risco::ADJCALLSTACKDOWN, Risco::ADJCALLSTACKUP),
        Subtarget(st), TII(tii)
{ }


const unsigned* RiscoRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const
{
  static const unsigned CalleeSavedRegs[] = {
    Risco::S0, Risco::S1, Risco::S2, Risco::S3, Risco::S4,
    Risco::S5, Risco::S6, Risco::S7, Risco::S8, Risco::S9,
    0
  };

  return CalleeSavedRegs;
}


BitVector RiscoRegisterInfo::getReservedRegs(const MachineFunction &MF) const
{
  BitVector Reserved(getNumRegs());
  Reserved.set(Risco::ZERO);
  Reserved.set(Risco::PSW);
  Reserved.set(Risco::RA);
  Reserved.set(Risco::FP);
  Reserved.set(Risco::SP);
  
  return Reserved;
}


bool RiscoRegisterInfo::hasFP(const MachineFunction &MF) const
{
  return true;
}


void RiscoRegisterInfo::
eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
        MachineBasicBlock::iterator I) const
{
  MachineInstr &MI = *I;
  DebugLoc dl = MI.getDebugLoc();

  int Size = MI.getOperand(0).getImm();
  if (MI.getOpcode() == Risco::ADJCALLSTACKDOWN)
    Size = -Size;
  
  if (Size)
    BuildMI(MBB, I, dl, TII.get(Risco::ADD_f2), Risco::SP).addReg(Risco::SP).addImm(Size);
  
  MBB.erase(I);
}


void RiscoRegisterInfo::
eliminateFrameIndex(MachineBasicBlock::iterator II, 
        int spAdj, RegScavenger *RS) const
{
  assert(spAdj == 0 && "Unexpected");

  unsigned i = 0;
  MachineInstr &mInstr = *II;
  DebugLoc debugLoc = mInstr.getDebugLoc();
  
  while (!mInstr.getOperand(i).isFI()) {
    ++i;
    assert(i < mInstr.getNumOperands() && "Instr doesn't have FrameIndex operand!");
  }

  int frameIndex = mInstr.getOperand(i).getIndex();

  // Addressable stack objects are accessed using neg. offsets from %fp
  MachineFunction &MF = *mInstr.getParent()->getParent();
  int Offset = MF.getFrameInfo()->getObjectOffset(frameIndex) +
          mInstr.getOperand(i + 1).getImm();

  // If the offset is small enough to fit in the immediate field, directly
  // encode it.
  mInstr.getOperand(i).ChangeToRegister(Risco::FP, false);
  mInstr.getOperand(i + 1).ChangeToImmediate(Offset);
}


void RiscoRegisterInfo::
processFunctionBeforeFrameFinalized(MachineFunction &MF) const
{ }


void RiscoRegisterInfo::
emitPrologue(MachineFunction &mFunction) const
{
  MachineBasicBlock &mBasicBlock = mFunction.front();
  MachineFrameInfo *mFrameInfo = mFunction.getFrameInfo();
  MachineBasicBlock::iterator mBB_it = mBasicBlock.begin();
  
  DebugLoc debugLoc = mBB_it != mBasicBlock.end() ? mBB_it->getDebugLoc() : DebugLoc();

  // Get the number of bytes to allocate from the FrameInfo
  int NumBytes = (int) mFrameInfo->getStackSize();

  // Emit the correct save instruction based on the number of bytes in
  // the frame.
  //    1 word for address of returned aggregate-value
  // +  5 words for passing parameters on the stack
  // ----------
  //   6 words * 4 bytes per word = 24 bytes
  NumBytes += 24;

  BuildMI(mBasicBlock, mBB_it, debugLoc, TII.get(Risco::ENTER_f2), Risco::SP)
          .addReg(Risco::SP).addImm(NumBytes);
}


void RiscoRegisterInfo::
emitEpilogue(MachineFunction &mFunction, MachineBasicBlock &mBasicBlock) const
{
  MachineBasicBlock::iterator mBB_it = prior(mBasicBlock.end());
  DebugLoc debugLoc = mBB_it->getDebugLoc();
  
  assert(mBB_it->getOpcode() == Risco::RET &&
          "Can only put epilog before 'ret' instruction!");
  
  BuildMI(mBasicBlock, mBB_it, debugLoc, TII.get(Risco::LEAVE_f1), Risco::ZERO)
          .addReg(Risco::R0)
          .addReg(Risco::R0);
}


unsigned RiscoRegisterInfo::getRARegister() const
{
  return Risco::RA;
}


unsigned RiscoRegisterInfo::getFrameRegister(const MachineFunction &MF) const
{
  return Risco::FP;
}


int RiscoRegisterInfo::getDwarfRegNum(unsigned RegNum, bool isEH) const
{
  return RiscoGenRegisterInfo::getDwarfRegNumFull(RegNum, 0);
}

#include "RiscoGenRegisterInfo.inc"
