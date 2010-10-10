//===- RiscoRegisterInfo.td - Risco Register defs ------------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//


// Generic Risco Format
class RiscoInstr<dag outs, dag ins, string asmstr, list<dag> pattern> : Instruction
{
  let Namespace = "Risco";

  int Format = 0;
  bit isPseudo = 0;

  dag OutOperandList = outs;
  dag InOperandList  = ins;

  let AsmString = asmstr;
  let Pattern   = pattern;
}


//===----------------------------------------------------------------------===//
// Format 1 instruction class in Risco
//===----------------------------------------------------------------------===//

class F1<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RiscoInstr<outs, ins, asmstr, pattern>
{
  let Format = 1;
}


//===----------------------------------------------------------------------===//
// Format 2 instruction class in Risco
//===----------------------------------------------------------------------===//

class F2<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RiscoInstr<outs, ins, asmstr, pattern>
{
  let Format = 2;
}


//===----------------------------------------------------------------------===//
// Format 3 instruction class in Risco
//===----------------------------------------------------------------------===//

class F3<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RiscoInstr<outs, ins, asmstr, pattern>
{
  let Format = 3;
}


//===----------------------------------------------------------------------===//
// Format 4 instruction class in Risco
//===----------------------------------------------------------------------===//

class F4<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RiscoInstr<outs, ins, asmstr, pattern>
{
  let Format = 4;
}


//===----------------------------------------------------------------------===//
// Format 5 instruction class in Risco
//===----------------------------------------------------------------------===//

class F5<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RiscoInstr<outs, ins, asmstr, pattern>
{
  let Format = 5;
}
