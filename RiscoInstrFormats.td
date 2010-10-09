//===- RiscoRegisterInfo.td - Risco Register defs ------------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//


// Generic Risco Format
class RiscoInstr<bits<2> _t1_t0, bits<5> _c4_c0, bits<1> _aps,
                dag outs, dag ins, string asmstr, list<dag> pattern> : Instruction
{
  field bits<32> Inst;

  let Namespace = "Risco";

  bits<2> t1_t0 = _t1_t0;
  bits<5> c4_c0 = _c4_c0;
  bits<1> aps   = _aps;

  bits<2> f1_f0;
  bits<5> dst;

  let Inst{31-30} = t1_t0;
  let Inst{29-25} = c4_c0;
  let Inst{24}    = aps;
  let Inst{23-22} = f1_f0;
  let Inst{21-17} = dst;

  dag OutOperandList = outs;
  dag InOperandList  = ins;

  let AsmString   = asmstr;
  let Pattern     = pattern;
}


// Risco Pseudo Instructions Format
class RiscoPseudo<dag outs, dag ins, string asmstr, list<dag> pattern> :
      RiscoInstr<outs, ins, asmstr, pattern, IIPseudo>;


//===----------------------------------------------------------------------===//
// Format 1 instruction class in Risco
//===----------------------------------------------------------------------===//

class F1<bits<2> T, bits<5> C, bits<1> APS,
         dag outs, dag ins, string asmstr,
         list<dag> pattern> :
      RiscoInstr<T, C, APS, outs, ins, asmstr, pattern>
{
  bits<5> ft1;
  bits<5> ft2;

  let f1_f0 = 0b00;

  let Inst{16-12} = ft1;
  let Inst{11}    = 0;
  let Inst{10-6}  = ft2;
  let Inst{5-0}   = 0;
}


//===----------------------------------------------------------------------===//
// Format 2 instruction class in Risco
//===----------------------------------------------------------------------===//

class F2<bits<2> T, bits<5> C, bits<1> APS,
         dag outs, dag ins, string asmstr,
         list<dag> pattern> :
      RiscoInstr<T, C, APS, outs, ins, asmstr, pattern>
{
  bits<5> ft1;
  bits<11> kpe;

  let f1_f0 = 0b00;

  let Inst{16-12} = ft1;
  let Inst{11}    = 1;
  let Inst{10-0}  = kpe;
}


//===----------------------------------------------------------------------===//
// Format 3 instruction class in Risco
//===----------------------------------------------------------------------===//

class F3<bits<2> T, bits<5> C, bits<1> APS,
         dag outs, dag ins, string asmstr,
         list<dag> pattern> :
      RiscoInstr<T, C, APS, outs, ins, asmstr, pattern>
{
  bits<17> kgl;

  let f1_f0 = 0b01;

  let Inst{16-0} = kgl;
}


//===----------------------------------------------------------------------===//
// Format 4 instruction class in Risco
//===----------------------------------------------------------------------===//

class F4<bits<2> T, bits<5> C, bits<1> APS,
         dag outs, dag ins, string asmstr,
         list<dag> pattern> :
      RiscoInstr<T, C, APS, outs, ins, asmstr, pattern>
{
  bits<17> kgh;

  let f1_f0 = 0b10;

  let Inst{16-0} = kgh;
}


//===----------------------------------------------------------------------===//
// Format 5 instruction class in Risco
//===----------------------------------------------------------------------===//

class F5<bits<2> T, bits<5> C, bits<1> APS,
         dag outs, dag ins, string asmstr,
         list<dag> pattern> :
      RiscoInstr<T, C, APS, outs, ins, asmstr, pattern>
{
  bits<17> kgl;

  let f1_f0 = 0b11;

  let Inst{16-0} = kgl;
}
