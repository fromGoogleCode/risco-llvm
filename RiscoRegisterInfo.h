//===- RiscoRegisterInfo.h - Risco Register Information Impl ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the Risco implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef RISCOREGISTERINFO_H
#define RISCOREGISTERINFO_H

#include "llvm/Target/TargetRegisterInfo.h"
#include "RiscoGenRegisterInfo.h.inc"


namespace llvm {

  class RiscoSubtarget;
  class TargetInstrInfo;
  class Type;

  struct RiscoRegisterInfo : public RiscoGenRegisterInfo {
    RiscoSubtarget &Subtarget;
    const TargetInstrInfo &TII;

    RiscoRegisterInfo(RiscoSubtarget &st, const TargetInstrInfo & tii);

    /// Code Generation virtual methods...
    const unsigned *getCalleeSavedRegs(const MachineFunction *MF = 0) const;

    BitVector getReservedRegs(const MachineFunction & MF) const;

    bool hasFP(const MachineFunction & MF) const;

    void eliminateCallFramePseudoInstr(MachineFunction &MF,
            MachineBasicBlock &MBB,
            MachineBasicBlock::iterator I) const;

    void eliminateFrameIndex(MachineBasicBlock::iterator II,
            int SPAdj, RegScavenger *RS = NULL) const;

    void processFunctionBeforeFrameFinalized(MachineFunction & MF) const;

    void emitPrologue(MachineFunction & MF) const;
    void emitEpilogue(MachineFunction &MF, MachineBasicBlock & MBB) const;

    // Debug information queries.
    unsigned getRARegister() const;
    unsigned getFrameRegister(const MachineFunction & MF) const;

    int RiscoRegisterInfo::getDwarfRegNum(unsigned RegNum, bool isEH) const;
  };

} // end namespace llvm

#endif
