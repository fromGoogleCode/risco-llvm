//===- RiscoInstrInfo.cpp - Risco Instruction Information -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the Risco implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "Risco.h"
#include "RiscoInstrInfo.h"
#include "RiscoSubtarget.h"

#include "RiscoGenInstrInfo.inc"
#include "RiscoMachineFunctionInfo.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/ErrorHandling.h"
using namespace llvm;


RiscoInstrInfo::RiscoInstrInfo(RiscoSubtarget &ST)
    : TargetInstrInfoImpl(RiscoInsts, array_lengthof(RiscoInsts)),
      RI(ST, *this), Subtarget(ST)
{ }


/// isLoadFromStackSlot - If the specified machine instruction is a direct
/// load from a stack slot, return the virtual or physical register number of
/// the destination along with the FrameIndex of the loaded stack slot.  If
/// not, return 0.  This predicate must return 0 if the instruction has
/// any side effects other than loading from the stack slot.

unsigned RiscoInstrInfo::
isLoadFromStackSlot(const MachineInstr *mInstr, int &FrameIndex) const
{
  if (mInstr->getOpcode() == Risco::LD_f2) {
    if (mInstr->getOperand(1).isFI() && mInstr->getOperand(2).isImm() &&
            mInstr->getOperand(2).getImm() == 0) {
      FrameIndex = mInstr->getOperand(1).getIndex();
      return mInstr->getOperand(0).getReg();
    }
  }
  
  return 0;
}


/// isStoreToStackSlot - If the specified machine instruction is a direct
/// store to a stack slot, return the virtual or physical register number of
/// the source reg along with the FrameIndex of the loaded stack slot.  If
/// not, return 0.  This predicate must return 0 if the instruction has
/// any side effects other than storing to the stack slot.

unsigned RiscoInstrInfo::
isStoreToStackSlot(const MachineInstr *mInstr, int &FrameIndex) const
{
  if (mInstr->getOpcode() == Risco::ST_f2) {
    if (mInstr->getOperand(0).isFI() && mInstr->getOperand(1).isImm() &&
            mInstr->getOperand(1).getImm() == 0) {
      FrameIndex = mInstr->getOperand(0).getIndex();
      return mInstr->getOperand(2).getReg();
    }
  }
  
  return 0;
}


/// InsertBranch - Insert branch code into the end of the specified
/// MachineBasicBlock.  The operands to this method are the same as those
/// returned by AnalyzeBranch.  This is only invoked in cases where
/// AnalyzeBranch returns success. It returns the number of instructions
/// inserted.
///
/// It is also invoked by tail merging to add unconditional branches in
/// cases where AnalyzeBranch doesn't apply because there was no original
/// branch to analyze.  At least this much must be implemented, else tail
/// merging needs to be disabled.
///
unsigned RiscoInstrInfo::
InsertBranch(MachineBasicBlock &mBasicBlock,
             MachineBasicBlock *trueBB,
             MachineBasicBlock *falseBB,
             const SmallVectorImpl<MachineOperand> &Cond,
             DebugLoc debugLoc) const
{
  // Can only insert uncond branches so far.
  assert(Cond.empty() && !falseBB && trueBB && "Can only handle uncond branches!");
  
  BuildMI(&mBasicBlock, debugLoc, get(Risco::JMP)).addMBB(trueBB);
  return 1;
}


/// copyPhysReg - Emit instructions to copy a pair of physical registers.
///
void RiscoInstrInfo::copyPhysReg(
        MachineBasicBlock &mBasicBlock,
        MachineBasicBlock::iterator it,
        DebugLoc debugLoc,
        unsigned DestReg, unsigned SrcReg,
        bool KillSrc) const
{
  BuildMI(mBasicBlock, it, debugLoc, get(Risco::OR_f1), DestReg)
    .addReg(Risco::ZERO)
    .addReg(SrcReg, getKillRegState(KillSrc));
}


/// storeRegToStackSlot - Store the specified register of the given register
/// class to the specified stack frame index. The store instruction is to be
/// added to the given machine basic block before the specified machine
/// instruction. If isKill is true, the register operand is the last use and
/// must be marked kill.
///
void RiscoInstrInfo::
storeRegToStackSlot(
        MachineBasicBlock &mBasicBlock,
        MachineBasicBlock::iterator it,
        unsigned SrcReg, bool isKill, int FI,
        const TargetRegisterClass *RegClass,
        const TargetRegisterInfo *tRegInfo) const
{
  DebugLoc debugLoc;
  if (it != mBasicBlock.end()) debugLoc = it->getDebugLoc();

  // On the order of operands here: think "[FrameIdx + 0] = SrcReg".
  BuildMI(mBasicBlock, it, debugLoc, get(Risco::ST_f2))
    .addFrameIndex(FI)
    .addImm(0)
    .addReg(SrcReg, getKillRegState(isKill));
}


/// loadRegFromStackSlot - Load the specified register of the given register
/// class from the specified stack frame index. The load instruction is to be
/// added to the given machine basic block before the specified machine
/// instruction.
///
void RiscoInstrInfo::
loadRegFromStackSlot(
        MachineBasicBlock &mBasicBlock,
        MachineBasicBlock::iterator it,
        unsigned DestReg, int FI,
        const TargetRegisterClass *RegClass,
        const TargetRegisterInfo *tRegInfo) const
{
  DebugLoc debugLoc;
  if (it != mBasicBlock.end()) debugLoc = it->getDebugLoc();

  BuildMI(mBasicBlock, it, debugLoc, get(Risco::LD_f2), DestReg)
    .addFrameIndex(FI)
    .addImm(0);
}
