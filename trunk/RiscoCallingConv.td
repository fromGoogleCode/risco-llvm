//===- RiscoCallingConv.td - Calling Conventions for Risco ---*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
// This describes the calling conventions for Risco architecture.
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
// Risco 32 bits C Calling Convention
//===----------------------------------------------------------------------===//


def CC_Risco32 : CallingConv<[
  // Promote i8/i16 arguments to i32.
  CCIfType<[i8, i16], CCPromoteToType<i32>>,

  // Integer arguments are passed in integer registers.
  CCIfType<[i32], CCAssignToReg<[A0, A1, A2, A3, A4]>>,

  // The rest are assigned stack slots
  CCAssignToStack<4, 4>
]>;


def RetCC_Risco32 : CallingConv<[
  // i32 are returned in register V0
  CCIfType<[i32], CCAssignToReg<[V0]>>,

  // The rest are returned on the stack
  CCAssignToStack<4, 4>
]>;
