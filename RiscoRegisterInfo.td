//===- RiscoRegisterInfo.td - Risco Register defs ------------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//


//===----------------------------------------------------------------------===//
//  Declarations that describe the RISCO register file
//===----------------------------------------------------------------------===//

// We have a bank of 32 registers.
class RiscoReg<bits<5> num, string n> : Register<n> {
  field bits<5> Num = num;
  let Namespace = "Risco";
  let DwarfNumbers = [-1];
}


//===----------------------------------------------------------------------===//
//  Registers
//===----------------------------------------------------------------------===//

let Namespace = "Risco" in {
  def ZERO : RiscoReg<0,  "$zero">;
  def PSW  : RiscoReg<1,  "$psw">;
  def V0   : RiscoReg<2,  "$v0">;

  def A0   : RiscoReg<3,  "$a0">;
  def A1   : RiscoReg<4,  "$a1">;
  def A2   : RiscoReg<5,  "$a2">;
  def A3   : RiscoReg<6,  "$a3">;
  def A4   : RiscoReg<7,  "$a4">;

  def T0   : RiscoReg<8,  "$t0">;
  def T1   : RiscoReg<9,  "$t1">;
  def T2   : RiscoReg<10, "$t2">;
  def T3   : RiscoReg<11, "$t3">;
  def T4   : RiscoReg<12, "$t4">;
  def T5   : RiscoReg<13, "$t5">;
  def T6   : RiscoReg<14, "$t6">;
  def T7   : RiscoReg<15, "$t7">;
  def T8   : RiscoReg<16, "$t8">;
  def T9   : RiscoReg<17, "$t9">;

  def S0   : RiscoReg<18, "$s0">;
  def S1   : RiscoReg<19, "$s1">;
  def S2   : RiscoReg<20, "$s2">;
  def S3   : RiscoReg<21, "$s3">;
  def S4   : RiscoReg<22, "$s4">;
  def S5   : RiscoReg<23, "$s5">;
  def S6   : RiscoReg<24, "$s6">;
  def S7   : RiscoReg<25, "$s7">;
  def S8   : RiscoReg<26, "$s8">;
  def S9   : RiscoReg<27, "$s9">;

  def RA   : RiscoReg<28, "$ra">;
  def FP   : RiscoReg<29, "$fp">;
  def SP   : RiscoReg<30, "$sp">;
}


//===----------------------------------------------------------------------===//
// Register Classes
//===----------------------------------------------------------------------===//

def IntReg : RegisterClass<"Risco", [i32], 32,
  // Return Values and Arguments
  [V0, A0, A1, A2, A3, A4,
  // Caller saved
  T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, 
  // Callee saved
  S0, S1, S2, S3, S4, S5, S6, S7, S8, S9,
  // Reserved
  ZERO, PSW, RA, FP, SP]>
{
  let MethodProtos = [{
    iterator allocation_order_end(const MachineFunction &MF) const;
  }];
  let MethodBodies = [{
    CPURegsClass::iterator
    CPURegsClass::allocation_order_end(const MachineFunction &MF) const {
      // The last 5 registers on the list above are reserved
      return end()-5;
    }
  }];
}
