//===- RiscoInstrInfo.td - Risco Register defs ---------------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//



//===----------------------------------------------------------------------===//
// Instruction format superclass
//===----------------------------------------------------------------------===//

include "RiscoInstrFormats.td"



//===----------------------------------------------------------------------===//
// Risco profiles and nodes
//===----------------------------------------------------------------------===//


// Profiles

def SDTRIjmpcc : SDTypeProfile< 0, 2,
  [ SDTCisVT<0, OtherVT>, SDTCisVT<1, i32> ]
>;

def SDT_RICall : SDTypeProfile< 0, 1,
  [ SDTCisVT<0, i32> ]
>;

def SDT_RICallSeqStart : SDCallSeqStart <[ SDTCisVT<0, i32> ]>;
def SDT_RICallSeqEnd   : SDCallSeqEnd   <[ SDTCisVT<0, i32>,
                                           SDTCisVT<0, i32> ]>;


// SelectionDAG nodes

def RIcmpicc : SDNode<"RIISD::CMPICC", SDTIntBinOp, [SDNPOutFlag]>;
def RIjmpicc : SDNode<"RIISD::JMPICC", SDTRIjmpcc, [SDNPHasChain, SDNPInFlag]>;

def RIhi     : SDNode<"RIISD::HI", SDTIntUnaryOp>;
def RIlo     : SDNode<"RIISD::LO", SDTIntUnaryOp>;

def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_RICallSeqStart,
  [SDNPHasChain, SDNPOutFlag]>;

def callseq_end   : SDNode<"ISD::CALLSEQ_END", SDT_RICallSeqEnd,
  [SDNPHasChain, SDNPOptInFlag, SDNPOutFlag]>;

def call     : SDNode<"RIISD::CALL", SDT_RICall,
  [SDNPHasChain, SDNPOptInFlag, SDNPOutFlag]>;

def retflag  : SDNode<"RIISO::RET_FLAG", SDTNone,
  [SDNPHasChain, SDNPOptInFlag]>;



//===----------------------------------------------------------------------===//
// Risco Operand, Complex Patterns and Transformations Definitions.
//===----------------------------------------------------------------------===//

// Instruction operand types
def brtargetOp    : Operand<OtherVT>;
def calltargetOp  : Operand<i32>;
def imm11Op       : Operand<i32>;
def imm17Op       : Operand<i32>;

let PrintMethod = "printOpRegZero" in
  def opRegZero     : Operand<i32>;

let PrintMethod = "printCCOperand" in
  def CCOp    : Operand<i32>;


// Node immediate fits as 11-bit sign extended on target immediate.
def imm11Pat  : PatLeaf<(imm), [{ return isInt<11>(N->getSExtValue()); }]>;

// Node immediate fits as 17-bit sign extended on target immediate.
def imm17Pat  : PatLeaf<(imm), [{ return isInt<17>(N->getSExtValue()); }]>;

// Node immediate is zero
def imm0Pat : PatLeaf<(imm), [{ return N->getSExtValue() == 0; }]>;


// Transformation Function - get the lower 16 bits.
def LO16 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant(
      (unsigned)N->getZExtValue() & ((1<<17)-1), MVT::i32
  );
}]>;

// Transformation Function - get the higher 16 bits.
def HI16 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant(
      (unsigned)N->getZExtValue() >> 16, MVT::i32
  );
}]>;


// Pattern for SETHI immediates
def SETHIimm : PatLeaf<(imm), [{
  return (((unsigned)N->getZExtValue() >> 16) << 16) ==
         (unsigned)N->getZExtValue();
}], HI16>;

// Pattern for SETLO immediates
def SETLOimm : PatLeaf<(imm), [{
  return (((unsigned)N->getZExtValue() >> 16) == 0);
}], LO16>;


// Addressing modes patterns
def ADDRrr : ComplexPattern<i32, 2, "SelectADDrrr", [], []>;
def ADDRri : ComplexPattern<i32, 2, "SelectADDrri", [frameindex], []>;


// Address operands
let PrintMethod = "printMemOperand" in {
  def MEMrrOp : Operand<i32> {
    let MIOperandInfo = (ops IntReg, IntReg);
  }

  def MEMriOp : Operand<i32> {
    let MIOperandInfo = (ops IntReg, imm11Op);
  }
}



//===----------------------------------------------------------------------===//
// Instructions condition codes
//===----------------------------------------------------------------------===//

class ICCPat<int N> : PatLeaf<(i32 N)>;
def ICC_TR  : ICCPat<0b11111>;
def ICC_NS  : ICCPat<0b10001>;
def ICC_CS  : CCPat<0b10010>;
def ICC_OS  : ICCPat<0b10100>;
def ICC_ZS  : ICCPat<0b11000>;
def ICC_GE  : ICCPat<0b10011>;
def ICC_GT  : ICCPat<0b10110>;
def ICC_EQ  : ICCPat<0b11100>;

def ICC_FL  : ICCPat<0b00000>;
def ICC_NN  : ICCPat<0b00001>;
def ICC_NC  : ICCPat<0b00010>;
def ICC_NO  : ICCPat<0b00100>;
def ICC_NZ  : ICCPat<0b01000>;
def ICC_LT  : ICCPat<0b00011>;
def ICC_LE  : ICCPat<0b00110>;
def ICC_NE  : ICCPat<0b01100>;



//===----------------------------------------------------------------------===//
// Instructions specific formats
//===----------------------------------------------------------------------===//


multiclass F_12np<string mnem> {
  def _f1 : F1<(outs IntReg:$dst), (ins IntReg:$a, IntReg:$b),
               !strconcat(mnem, " $dst, $a, $b"), []>;

  def _f2 : F2<(outs IntReg:$dst), (ins IntReg:$a, imm11Op:$b),
               !strconcat(mnem, " $dst, $a, $b"), []>;
}


multiclass ArithLogicInstr<string mnem, SDNode OpNode> {
  def _f1 : F1<(outs IntReg:$dst), (ins IntReg:$a, IntReg:$b),
               !strconcat(mnem, " $dst, $a, $b"),
               [(set IntReg:$dst, (OpNode IntReg:$a, IntReg:$b))]>;

  def _f2 : F2<(outs IntReg:$dst), (ins IntReg:$a, imm11Op:$b),
               !strconcat(mnem, " $dst, $a, $b"),
               [(set IntReg:$dst, (OpNode IntReg:$a, imm11Pat:$b))]>;

  def _f3 : F3<(outs IntReg:$dst), (ins imm17Op:$b),
               !strconcat(mnem, " $dst, %R0, $b"),
               [(set IntReg:$dst, (OpNode 0, imm17Pat:$b))]>;

  /*
  let Constraints = "$dst = $a" in {
    def _f4 : F4<(outs IntReg:$dst), (ins IntReg:$a, imm17Op:$b),
                 !strconcat(mnem, " $dst, $a, $b"),
                 [(set IntReg:$dst, (OpNode IntReg:$a, imm17Pat:$b))]>;
  }
  */
}


multiclass RevArithInstr<string mnem, SDNode OpNode> {
  def _f2 : F2<(outs IntReg:$dst), (ins IntReg:$a, imm11Op:$b),
               !strconcat(mnem, " $dst, $a, $b"),
               [(set IntReg:$dst, (OpNode imm11Pat:$b, IntReg:$a))]>;

  def _f3 : F3<(outs IntReg:$dst), (ins imm17Op:$b),
               !strconcat(mnem, " $dst, %R0, $b"),
               [(set IntReg:$dst, (OpNode imm17Pat:$b, 0))]>;

  /*
  let Constraints = "$dst = $a" in
  def _f4 : F4<(outs IntReg:$dst), (ins IntReg:$a, imm17Op:$b),
               !strconcat(mnem, " $dst, $a, $b"),
               [(set IntReg:$dst, (OpNode imm17Pat:$b, IntReg:$a))]>;
  */
}


class SetHiInstr : F4<(outs IntReg:$dst), (ins i32imm:$src),
                      "sethi $dst, @$src",
                      [(set IntReg:$dst, SETHIimm:$src)]>;

class SetLoInstr : F1<(outs IntReg:$dst), (ins IntReg:$a, i32imm:$b),
                      "setlo ($dst, $a, $b)",
                      [(set IntReg:$dst, (add IntReg:$a, SETLOimm:$b))]>
{
  let isPseudo = 1;
}


let canFoldAsLoad = 1,
    hasDelaySlot = 1 in
multiclass LoadInstr<string mnem, PatFrag OpNode> {
  def _f1 : F1<(outs IntReg:$dst), (ins MEMrrOp:$addr),
               !strconcat(mnem, " $dst, [$addr]"),
               [(set IntReg:$dst, (OpNode ADDRrr:$addr))]>;

  def _f2 : F2<(outs IntReg:$dst), (ins MEMriOp:$addr),
               !strconcat(mnem, " $dst, [$addr]"),
               [(set IntReg:$dst, (OpNode ADDRri:$addr))]>;
}


multiclass StoreInstr<string mnem, PatFrag OpNode> {
  def _f1 : F1<(outs), (ins MEMrrOp:$addr, IntReg:$a),
               !strconcat(mnem, " [$addr], $a"),
               [(OpNode IntReg:$a, ADDRrr:$addr)]>;

  def _f2 : F2<(outs), (ins MEMriOp:$addr, IntReg:$a),
               !strconcat(mnem, " [$addr], $a"),
               [(OpNode IntReg:$a, ADDRri:$addr)]>;
}


let isBranch = 1,
    isTerminator = 1,
    hasDelaySlot = 1 in
{
  let isBarrier = 1 in
  class BranchInstr<string mnem>
        : F1<(outs), (ins brtargetOp:$dst),
             !strconcat(mnem, " $dst"),
             [(br bb:$dst)]>;

  let Uses = [PSW] in
  class CondBranchInstr<string mnem>
        : F1<(outs), (ins brtargetOp:$dst, CCOp:$cc),
             !strconcat(mnem, "$cc $dst"),
             [(RIjmpicc bb:$dst, imm:$cc)]>;
}


let isCall = 1,
    hasDelaySlot = 1,
    Uses = [A0, A1, A2, A3, A4],
    Defs = [T0, T1, T2, T3, T4, T5, T6, T7, T8, T9] in
multiclass CallInstr<string mnem> {
  // Indirect call (rr)
  def _f1 : F1<(outs), (ins MEMrrOp:$ptr),
               !strconcat(mnem, " $ptr"),
               [(call ADDRrr:$ptr)]>;

  // Indirect call (ri)
  def _f2 : F2<(outs), (ins MEMriOp:$ptr),
               !strconcat(mnem, " $ptr"),
               [(call ADDRri:$ptr)]>;

  // Direct call
  def _f3 : F3<(outs), (ins calltargetOp:$dst),
               !strconcat(mnem, " $dst"), []>;  
}



//===----------------------------------------------------------------------===//
// Pseudo instructions
//===----------------------------------------------------------------------===//

class Pseudo<dag outs, dag ins, string mnem, list<dag> pattern>
  : F1<outs, ins, mnem, pattern> {
  let isPseudo = 1;
}

let Defs = [SP], Uses = [SP] in {
  def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i32imm:$amt),
                                "!ADJCALLSTACKDOWN $amt",
                                [(callseq_start timm:$amt)]>;

  def ADJCALLSTACKUP   : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                                "!ADJCALLSTACKUP $amt1",
                                [(callseq_end timm:$amt1, timm:$amt2)]>;
}

def RET : F1<(outs), (ins), "ret", [(retflag)]> {
  let isReturn = 1;
  let isTerminator = 1;
  let hasDelaySlot = 1;
  let isBarrier = 1;
}



//===----------------------------------------------------------------------===//
// Instruction definition
//===----------------------------------------------------------------------===//


def NOP : RiscoInstr<(outs), (ins), "nop", []>;

let isCommutable = 1 in {
  defm ADD : ArithLogicInstr<"add", add>;
  defm AND : ArithLogicInstr<"and", and>;
  defm OR  : ArithLogicInstr<"or", or>;
  defm XOR : ArithLogicInstr<"xor", xor>;

  let Defs = [PSW] in {
    defm ADD_APS : ArithLogicInstr<"add!", addc>;
    defm SUB_APS : ArithLogicInstr<"sub!", RIcmpicc>;
  }
}

defm SUB  : ArithLogicInstr<"sub", sub>;
defm SUBR : RevArithInstr<"subr", sub>;

defm SLL  : ArithLogicInstr<"sll", shl>;
defm SRL  : ArithLogicInstr<"srl", srl>;
defm SRA  : ArithLogicInstr<"sra", sra>;

def SETHI : SetHiInstr;

defm LD : LoadInstr<"ld", load>;
defm ST : StoreInstr<"st", store>;

let Uses = [SP], Defs = [SP] in {
  defm ENTER : F_12np<"enter">;
  defm LEAVE : F_12np<"leave">;
}

def JMP     : BranchInstr<"jmp">;
def JMPCOND : CondBranchInstr<"jmp">;

defm CALL   : CallInstr<"call">;



//===----------------------------------------------------------------------===//
//  Arbitrary patterns that map to one or more instructions
//===----------------------------------------------------------------------===//


// Small immediates
def : Pat<(i32 imm11Pat:$val), (OR_f2 ZERO, imm:$val)>;
def : Pat<(i32 imm17Pat:$val), (OR_f3 imm:$val)>;

// Arbitrary immediates
def : Pat<(i32 imm:$val), (SETLO (SETHI (HI16 imm:$val)), (LO16 imm:$val))>;


// Global addresses, constant pool entries

def : Pat<(RIhi tglobaladdr:$in), (SETHI tglobaladdr:$in)>;
def : Pat<(RIlo tglobaladdr:$in), (SETLO ZERO, tglobaladdr:$in)>;

def : Pat<(RIhi tconstpool:$in), (SETHI tconstpool:$in)>;
def : Pat<(RIlo tconstpool:$in), (SETLO ZERO, tconstpool:$in)>;

def : Pat<(add IntReg:$r, (RIlo tglobaladdr:$in)),
          (ADD_f2 IntReg:$r, tglobaladdr:$in)>;

def : Pat<(add IntReg:$r, (RIlo tconstpool:$in)),
          (ADD_f2 IntReg:$r, tconstpool:$in)>;


// Calls
def : Pat<(call tglobaladdr:$dst),  (CALL_f3 tglobaladdr:$dst)>;
def : Pat<(call texternalsym:$dst), (CALL_f3 texternalsym:$dst)>;

// Risco does not have "not", so we expand our way
def : Pat<(not IntReg:$in), (SUB_f1 ZERO, IntReg:$in)>;
