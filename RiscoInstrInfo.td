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

def RIhi     : SDNode<"RIISD::HI", SDIntUnaryOp>;
def RIlo     : SDNode<"RIISD::LO", SDIntUnaryOp>;

def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_RICallSeqStart,
  [SDNPHasChain, SDNPOutFlag]>;

def callseq_end   : SDNode<"ISD::CALLSEQ_END", SDT_RICallSeqEnd,
  [SDNPHasChain, SDNPOptInFlag, SDNPOutFlag>;

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
def imm11Op       : Operand<i11>;
def imm17Op       : Operand<i17>;
def opRegZero     : Operand<i5>;

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
  return getI32Imm((unsigned)N->getZExtValue() & 0xFFFF);
}]>;

// Transformation Function - get the higher 16 bits.
def HI16 : SDNodeXForm<imm, [{
  return getI32Imm((unsigned)N->getZExtValue() >> 16);
}]>;


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

class CCPat<int N> : PatLeaf<(i32 N)>;
def CC_TR  : CCPat<0b11111>;
def CC_NS  : CCPat<0b10001>;
def CC_CS  : CCPat<0b10010>;
def CC_OS  : CCPat<0b10100>;
def CC_ZS  : CCPat<0b11000>;
def CC_GE  : CCPat<0b10011>;
def CC_GT  : CCPat<0b10110>;
def CC_EQ  : CCPat<0b11100>;

def CC_FL  : CCPat<0b00000>;
def CC_NN  : CCPat<0b00001>;
def CC_NC  : CCPat<0b00010>;
def CC_NO  : CCPat<0b00100>;
def CC_NZ  : CCPat<0b01000>;
def CC_LT  : CCPat<0b00011>;
def CC_LE  : CCPat<0b00110>;
def CC_NE  : CCPat<0b01100>;



//===----------------------------------------------------------------------===//
// Instructions specific formats
//===----------------------------------------------------------------------===//


multiclass F_12np<string mnem> {
  def _F1 : F1<(outs IntReg:$dst), (ins IntReg:$a, IntReg $b),
               !strconcat(mnem, " $dst, $a, $b"), []>;

  def _F2 : F2<(outs IntReg:$dst), (ins IntReg:$a, imm11Op:$b),
               !strconcat(mnem, " $dst, $a, $b"), []>;
}

let Itinerary = IIAlu in 
multiclass ArithLogicInstr<string mnem, SDNode OpNode> {
  def _F1 : F1<(outs IntReg:$dst), (ins IntReg:$a, IntReg:$b),
               !strconcat(mnem, " $dst, $a, $b"),
               [(set IntReg:$dst, (OpNode IntReg:$a, IntReg:$b))]>;

  def _F2 : F2<(outs IntReg:$dst), (ins IntReg:$a, imm11Op:$b),
               !strconcat(mnem, " $dst, $a, $b"),
               [(set IntReg:$dst, (OpNode IntReg:$a, imm11Pat:$b))]>;

  def _F3 : F3<(outs IntReg:$dst), (ins opRegZero:$z, imm17Op:$b),
               !strconcat(mnem, " $dst, $zero, $b"),
               [(set IntReg:$dst, (OpNode 0, imm17Pat:$b))]>;

  let Constraints = "$a = $b" in
  def _F4 : F4<(outs IntReg:$dst), (ins IntReg:$a, imm17Op:$b),
               !strconcat(mnem, " $dst, $a, $b"),
               [(set IntReg:$dst, (OpNode IntReg:$a, imm17Pat:$b))]>;
}


let Itinerary = IIAlu in
multiclass RevArithInstr<string mnem, SDNode OpNode> {
  def _F2 : F2<(outs IntReg:$dst), (ins IntReg:$a, imm11Op:$b),
               !strconcat(mnem, " $dst, $a, $b"),
               [(set IntReg:$dst, (OpNode imm11Pat:$b, IntReg:$a))]>;

  def _F3 : F3<(outs IntReg:$dst), (ins opRegZero:$z, imm17Op:$b),
               !strconcat(mnem, " $dst, $zero, $b"),
               [(set IntReg:$dst, (OpNode imm17Pat:$b, 0))]>;

  let Constraints = "$a = $b" in
  def _F4 : F4<(outs IntReg:$dst), (ins IntReg:$a, imm17Op:$b),
               !strconcat(mnem, " $dst, $a, $b"),
               [(set IntReg:$dst, (OpNode imm17Pat:$b, IntReg:$a))]>;
}


let Itinerary = IILoad,
    canFoldAsLoad = 1,
    hasDelaySlot = 1 in
multiclass LoadInstr<string mnem, SDNode OpNode> {
  def _F1 : F1<(outs IntReg:$dst), (ins MEMrrOp:$addr),
               !strconcat(mnem, " $dst, [$addr]"),
               [(set IntReg:$dst, (OpNode ADDRrr:$addr))]>;

  def _F2 : F2<(outs IntReg:$dst), (ins IntReg:$a, imm11Op:$b),
               !strconcat(mnem, " $dst, [$addr]"),
               [(set IntReg:$dst, (OpNode ADDRri:$addr))]>;
}


let Itinerary = IIStore in
multiclass StoreInstr<string mnem, SDNode OpNode> {
  def _F1 : F1<(outs), (ins MEMrrOp:$addr, IntReg:$a),
               !strconcat(mnem, " [$addr], $a",
               [(OpNode IntReg:$a, ADDRrr:$addr)]>;

  def _F2 : F2<(outs), (ins MEMriOp:$addr, IntReg:$a),
               !strconcat(mnem, " [$addr], $a",
               [(OpNode IntReg:$a, ADDRri:$addr)]>;
}


let Itinerary = IIBranch,
    isBranch = 1,
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
        : F1<(outs), (ins brtarget:$dst, CCOp:$cc),
             !strconcat(mnem, "$cc $dst",
             [(RIjmpicc bb:$dst, imm:$cc)]>;
}


let isCall = 1,
    hasDelaySlot = 1,
    Uses = [A0, A1, A2, A3, A4],
    Defs = [T0, T1, T2, T3, T4, T5, T6, T7, T8, T9] in
multiclass CallInstr<string mnem> {
  // Indirect call (rr)
  def _F1 : F1<(outs), (ins MEMrrOp:$ptr),
               !strconcat(mnem, " $ptr"),
               [(call ADDRrr:$ptr)]>;

  // Indirect call (ri)
  def _F2 : F2<(outs), (ins MEMriOp:$ptr),
               !strconcat(mnem, " $ptr"),
               [(call ADDRri:$ptr)]>;

  // Direct call
  def _F3 : F3<(outs), (ins calltargetOp:$dst),
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
  def RIADJCALLSTACKDOWN : Pseudo<(outs), (ins i32imm:$amt),
                                  "!ADJCALLSTACKDOWN $amt",
                                  [(callseq_start timm:$amt)]>;

  def RIADJCALLSTACKUP   : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
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


def NOP : RiscoInstr<0,0,0,(outs),(ins),"nop",[]>;

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

defm LD : LoadInstr<"ld", load>;
defm ST : StoreInstr<"st", store>;

let Uses = [SP], Defs = [SP] in {
  defm ENTER : F_12np<"enter">;
  defm LEAVE : F_12np<"leave">;
}

defm JMP     : BranchInstr<"jmp">;
defm JMPCOND : CondBranchInstr<"jmp">;

defm CALL    : CallInstr<"call">;



//===----------------------------------------------------------------------===//
//  Arbitrary patterns that map to one or more instructions
//===----------------------------------------------------------------------===//

// Small immediates
def : Pat<(i32 immSExt16:$in),
          (ADDiu ZERO, imm:$in)>;
def : Pat<(i32 immZExt16:$in),
          (ORi ZERO, imm:$in)>;

// Arbitrary immediates
def : Pat<(i32 imm:$imm),
          (ORi (LUi (HI16 imm:$imm)), (LO16 imm:$imm))>;

// Carry patterns
def : Pat<(subc IntReg:$lhs, IntReg:$rhs),
          (SUBu IntReg:$lhs, IntReg:$rhs)>;
def : Pat<(addc IntReg:$lhs, IntReg:$rhs),
          (ADDu IntReg:$lhs, IntReg:$rhs)>;
def : Pat<(addc  IntReg:$src, imm:$imm),
          (ADDiu IntReg:$src, imm:$imm)>;

// Call
def : Pat<(RiscoJmpLink (i32 tglobaladdr:$dst)),
          (JAL tglobaladdr:$dst)>;
def : Pat<(RiscoJmpLink (i32 texternalsym:$dst)),
          (JAL texternalsym:$dst)>;
//def : Pat<(RiscoJmpLink IntReg:$dst),
//          (JALR IntReg:$dst)>;

// hi/lo relocs
def : Pat<(RiscoHi tglobaladdr:$in), (LUi tglobaladdr:$in)>;
def : Pat<(add IntReg:$hi, (RiscoLo tglobaladdr:$lo)),
          (ADDiu IntReg:$hi, tglobaladdr:$lo)>;

def : Pat<(RiscoHi tjumptable:$in), (LUi tjumptable:$in)>;
def : Pat<(add IntReg:$hi, (RiscoLo tjumptable:$lo)),
          (ADDiu IntReg:$hi, tjumptable:$lo)>;

def : Pat<(RiscoHi tconstpool:$in), (LUi tconstpool:$in)>;
def : Pat<(add IntReg:$hi, (RiscoLo tconstpool:$lo)),
          (ADDiu IntReg:$hi, tconstpool:$lo)>;

// gp_rel relocs
def : Pat<(add IntReg:$gp, (RiscoGPRel tglobaladdr:$in)),
          (ADDiu IntReg:$gp, tglobaladdr:$in)>;
def : Pat<(add IntReg:$gp, (RiscoGPRel tconstpool:$in)),
          (ADDiu IntReg:$gp, tconstpool:$in)>;

// Risco does not have "not", so we expand our way
def : Pat<(not IntReg:$in),
          (NOR IntReg:$in, ZERO)>;

// extended load and stores
def : Pat<(extloadi1  addr:$src), (LBu addr:$src)>;
def : Pat<(extloadi8  addr:$src), (LBu addr:$src)>;
def : Pat<(extloadi16 addr:$src), (LHu addr:$src)>;

// peepholes
def : Pat<(store (i32 0), addr:$dst), (SW ZERO, addr:$dst)>;

// brcond patterns
def : Pat<(brcond (setne IntReg:$lhs, 0), bb:$dst),
          (BNE IntReg:$lhs, ZERO, bb:$dst)>;
def : Pat<(brcond (seteq IntReg:$lhs, 0), bb:$dst),
          (BEQ IntReg:$lhs, ZERO, bb:$dst)>;

def : Pat<(brcond (setge IntReg:$lhs, IntReg:$rhs), bb:$dst),
          (BEQ (SLT IntReg:$lhs, IntReg:$rhs), ZERO, bb:$dst)>;
def : Pat<(brcond (setuge IntReg:$lhs, IntReg:$rhs), bb:$dst),
          (BEQ (SLTu IntReg:$lhs, IntReg:$rhs), ZERO, bb:$dst)>;
def : Pat<(brcond (setge IntReg:$lhs, immSExt16:$rhs), bb:$dst),
          (BEQ (SLTi IntReg:$lhs, immSExt16:$rhs), ZERO, bb:$dst)>;
def : Pat<(brcond (setuge IntReg:$lhs, immSExt16:$rhs), bb:$dst),
          (BEQ (SLTiu IntReg:$lhs, immSExt16:$rhs), ZERO, bb:$dst)>;

def : Pat<(brcond (setle IntReg:$lhs, IntReg:$rhs), bb:$dst),
          (BEQ (SLT IntReg:$rhs, IntReg:$lhs), ZERO, bb:$dst)>;
def : Pat<(brcond (setule IntReg:$lhs, IntReg:$rhs), bb:$dst),
          (BEQ (SLTu IntReg:$rhs, IntReg:$lhs), ZERO, bb:$dst)>;

def : Pat<(brcond IntReg:$cond, bb:$dst),
          (BNE IntReg:$cond, ZERO, bb:$dst)>;

// select patterns
def : Pat<(select (setge IntReg:$lhs, IntReg:$rhs), IntReg:$T, IntReg:$F),
          (MOVZ IntReg:$F, IntReg:$T, (SLT IntReg:$lhs, IntReg:$rhs))>;
def : Pat<(select (setuge IntReg:$lhs, IntReg:$rhs), IntReg:$T, IntReg:$F),
          (MOVZ IntReg:$F, IntReg:$T, (SLTu IntReg:$lhs, IntReg:$rhs))>;
def : Pat<(select (setge IntReg:$lhs, immSExt16:$rhs), IntReg:$T, IntReg:$F),
          (MOVZ IntReg:$F, IntReg:$T, (SLTi IntReg:$lhs, immSExt16:$rhs))>;
def : Pat<(select (setuge IntReg:$lh, immSExt16:$rh), IntReg:$T, IntReg:$F),
          (MOVZ IntReg:$F, IntReg:$T, (SLTiu IntReg:$lh, immSExt16:$rh))>;

def : Pat<(select (setle IntReg:$lhs, IntReg:$rhs), IntReg:$T, IntReg:$F),
          (MOVZ IntReg:$F, IntReg:$T, (SLT IntReg:$rhs, IntReg:$lhs))>;
def : Pat<(select (setule IntReg:$lhs, IntReg:$rhs), IntReg:$T, IntReg:$F),
          (MOVZ IntReg:$F, IntReg:$T, (SLTu IntReg:$rhs, IntReg:$lhs))>;

def : Pat<(select (seteq IntReg:$lhs, IntReg:$rhs), IntReg:$T, IntReg:$F),
          (MOVZ IntReg:$F, IntReg:$T, (XOR IntReg:$lhs, IntReg:$rhs))>;
def : Pat<(select (setne IntReg:$lhs, IntReg:$rhs), IntReg:$T, IntReg:$F),
          (MOVN IntReg:$F, IntReg:$T, (XOR IntReg:$lhs, IntReg:$rhs))>;

def : Pat<(select IntReg:$cond, IntReg:$T, IntReg:$F),
          (MOVN IntReg:$F, IntReg:$T, IntReg:$cond)>;

// setcc patterns
def : Pat<(seteq IntReg:$lhs, IntReg:$rhs),
          (SLTu (XOR IntReg:$lhs, IntReg:$rhs), 1)>;
def : Pat<(setne IntReg:$lhs, IntReg:$rhs),
          (SLTu ZERO, (XOR IntReg:$lhs, IntReg:$rhs))>;

def : Pat<(setle IntReg:$lhs, IntReg:$rhs),
          (XORi (SLT IntReg:$rhs, IntReg:$lhs), 1)>;
def : Pat<(setule IntReg:$lhs, IntReg:$rhs),
          (XORi (SLTu IntReg:$rhs, IntReg:$lhs), 1)>;

def : Pat<(setgt IntReg:$lhs, IntReg:$rhs),
          (SLT IntReg:$rhs, IntReg:$lhs)>;
def : Pat<(setugt IntReg:$lhs, IntReg:$rhs),
          (SLTu IntReg:$rhs, IntReg:$lhs)>;

def : Pat<(setge IntReg:$lhs, IntReg:$rhs),
          (XORi (SLT IntReg:$lhs, IntReg:$rhs), 1)>;
def : Pat<(setuge IntReg:$lhs, IntReg:$rhs),
          (XORi (SLTu IntReg:$lhs, IntReg:$rhs), 1)>;

def : Pat<(setge IntReg:$lhs, immSExt16:$rhs),
          (XORi (SLTi IntReg:$lhs, immSExt16:$rhs), 1)>;
def : Pat<(setuge IntReg:$lhs, immSExt16:$rhs),
          (XORi (SLTiu IntReg:$lhs, immSExt16:$rhs), 1)>;

//===----------------------------------------------------------------------===//
// Floating Point Support
//===----------------------------------------------------------------------===//

include "RiscoInstrFPU.td"

