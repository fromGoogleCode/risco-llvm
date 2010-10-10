//===- Risco.td - Describe the Risco Target Machine --------*- tablegen -*-===//
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



//===----------------------------------------------------------------------===//
// Target-independent interfaces which we are implementing
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"



//===----------------------------------------------------------------------===//
// Register File, Calling Conv, Instruction Descriptions
//===----------------------------------------------------------------------===//

include "RiscoRegisterInfo.td"
include "RiscoCallingConv.td"
include "RiscoInstrInfo.td"

def RiscoInstrInfo : InstrInfo;


//===----------------------------------------------------------------------===//
// Risco processors supported.
//===----------------------------------------------------------------------===//

def : Processor<"simulator", NoItineraries, []>;



//===----------------------------------------------------------------------===//
// Declare the target which we are implementing
//===----------------------------------------------------------------------===//

def Risco : Target {
  // Pull in Instruction Info:
  let InstructionSet = RiscoInstrInfo;
}
