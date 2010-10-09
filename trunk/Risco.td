//===- Risco.td - Describe the Risco Target Machine ----------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
// This is the top level entry point for the Risco target.
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
// Target-independent interfaces
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"


//===----------------------------------------------------------------------===//
// Register File, Calling Conv, Instruction Descriptions
//===----------------------------------------------------------------------===//

include "RiscoRegisterInfo.td"
include "RiscoSchedule.td"
include "RiscoInstrInfo.td"
include "RiscoCallingConv.td"

def RiscoInstrInfo : InstrInfo;


//===----------------------------------------------------------------------===//
// Risco processors supported.
//===----------------------------------------------------------------------===//


def : Processor<"simulator", RiscoGenericItineraries, []>;

def Risco : Target {
  let InstructionSet = RiscoInstrInfo;
}
