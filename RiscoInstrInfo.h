//===- RiscoInstrInfo.h - Risco Instruction Information ---------*- C++ -*-===//
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

#ifndef RISCOINSTRUCTIONINFO_H
#define RISCOINSTRUCTIONINFO_H

#include "llvm/Target/TargetInstrInfo.h"
#include "RiscoRegisterInfo.h"


namespace llvm {

  /// RIF - This namespace holds all of the target specific flags that
  /// instruction info tracks.
  ///
  namespace RIF {

    enum {
      Pseudo    = (1 << 0),
      Load      = (1 << 1),
      Store     = (1 << 2),
      DelaySlot = (1 << 3)
    };
  }

  class RiscoInstrInfo : public TargetInstrInfoImpl {
    const RiscoRegisterInfo RI;
    const RiscoSubtarget& Subtarget;
    
  public:
    explicit RiscoInstrInfo(RiscoSubtarget &ST);

    /// getRegisterInfo - TargetInstrInfo is a superset of MRegister info.  As
    /// such, whenever a client has an instance of instruction info, it should
    /// always be able to get register info as well (through this method).
    ///
    virtual const RiscoRegisterInfo &getRegisterInfo() const {
      return RI;
    }

    /// isLoadFromStackSlot - If the specified machine instruction is a direct
    /// load from a stack slot, return the virtual or physical register number of
    /// the destination along with the FrameIndex of the loaded stack slot.  If
    /// not, return 0.  This predicate must return 0 if the instruction has
    /// any side effects other than loading from the stack slot.
    virtual unsigned isLoadFromStackSlot(const MachineInstr *MI,
            int &FrameIndex) const;

    /// isStoreToStackSlot - If the specified machine instruction is a direct
    /// store to a stack slot, return the virtual or physical register number of
    /// the source reg along with the FrameIndex of the loaded stack slot.  If
    /// not, return 0.  This predicate must return 0 if the instruction has
    /// any side effects other than storing to the stack slot.
    virtual unsigned isStoreToStackSlot(const MachineInstr *MI,
            int &FrameIndex) const;


    virtual unsigned InsertBranch(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
            MachineBasicBlock *FBB,
            const SmallVectorImpl<MachineOperand> &Cond,
            DebugLoc DL) const;

    virtual void copyPhysReg(MachineBasicBlock &MBB,
            MachineBasicBlock::iterator I, DebugLoc DL,
            unsigned DestReg, unsigned SrcReg,
            bool KillSrc) const;

    virtual void storeRegToStackSlot(MachineBasicBlock &MBB,
            MachineBasicBlock::iterator MBBI,
            unsigned SrcReg, bool isKill, int FrameIndex,
            const TargetRegisterClass *RC,
            const TargetRegisterInfo *TRI) const;

    virtual void loadRegFromStackSlot(MachineBasicBlock &MBB,
            MachineBasicBlock::iterator MBBI,
            unsigned DestReg, int FrameIndex,
            const TargetRegisterClass *RC,
            const TargetRegisterInfo *TRI) const;
  };

}

#endif
