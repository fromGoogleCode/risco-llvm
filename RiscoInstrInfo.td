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

def SDT_RiscoRet          : SDTypeProfile<0, 1, [SDTCisInt<0>]>;
def SDT_RiscoCallSeqStart : SDCallSeqStart<[SDTCisVT<0, i32>]>;
def SDT_RiscoCallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;

// Return
def RiscoRet : SDNode<"RiscoISD::Ret", SDT_RiscoRet, [SDNPHasChain,
                     SDNPOptInFlag]>;

// These are target-independent nodes, but have target-specific formats.
def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_RiscoCallSeqStart,
                           [SDNPHasChain, SDNPOutFlag]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END", SDT_RiscoCallSeqEnd,
                           [SDNPHasChain, SDNPOptInFlag, SDNPOutFlag]>;

//===----------------------------------------------------------------------===//
// Risco Operand, Complex Patterns and Transformations Definitions.
//===----------------------------------------------------------------------===//

// Instruction operand types
def brtarget    : Operand<OtherVT>;
def calltarget  : Operand<i32>;
def imm11       : Operand<i11>;
def imm17       : Operand<i17>;

// Address operand
def mem : Operand<i32> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops simm11, CPURegs);
}

// Transformation Function - get the lower 16 bits.
def LO16 : SDNodeXForm<imm, [{
  return getI32Imm((unsigned)N->getZExtValue() & 0xFFFF);
}]>;

// Transformation Function - get the higher 16 bits.
def HI16 : SDNodeXForm<imm, [{
  return getI32Imm((unsigned)N->getZExtValue() >> 16);
}]>;

// Node immediate fits as 11-bit sign extended on target immediate.
def immSExt11  : PatLeaf<(imm), [{ return isInt<11>(N->getSExtValue()); }]>;

// Node immediate fits as 17-bit sign extended on target immediate.
def immSExt17  : PatLeaf<(imm), [{ return isInt<17>(N->getSExtValue()); }]>;

// Node immediate is zero
def immZero    : PatLeaf<(imm), [{ return N->getSExtValue() == 0; }]>;

// Mips Address Mode! SDNode frameindex could possibily be a match
// since load and store instructions from stack used it.
def addr : ComplexPattern<iPTR, 2, "SelectAddr", [frameindex], []>;

//===----------------------------------------------------------------------===//
// Instructions specific format
//===----------------------------------------------------------------------===//

class CC_VAL<int N> : PatLeaf<(i32 N)>;
def CC_TR  : ICC_VAL<0b11111>;
def CC_NS  : ICC_VAL<0b10001>;
def CC_CS  : ICC_VAL<0b10010>;
def CC_OS  : ICC_VAL<0b10100>;
def CC_ZS  : ICC_VAL<0b11000>;
def CC_GE  : ICC_VAL<0b10011>;
def CC_GT  : ICC_VAL<0b10110>;  
def CC_EQ  : ICC_VAL<0b11100>;

def CC_FL  : ICC_VAL<0b00000>;
def CC_NN  : ICC_VAL<0b00001>;
def CC_NC  : ICC_VAL<0b00010>;
def CC_NO  : ICC_VAL<0b00100>;
def CC_NZ  : ICC_VAL<0b01000>;
def CC_LT  : ICC_VAL<0b00011>;
def CC_LE  : ICC_VAL<0b00110>;
def CC_NE  : ICC_VAL<0b01100>;


multiclass BF1<dag outs, dag ins, string asmstr, list<dag> pattern> {
  def _0 : F1<?, ?, 0, outs, ins, asmstr, pattern, itin>;
  def _1 : F1<?, ?, 1, outs, ins, !strconcat(asmstr,"!"), pattern>
  { let defs = [PSW]; }
}

multiclass BF2<dag outs, dag ins, string asmstr, list<dag> pattern> {
  def _0 : F2<?, ?, 0, outs, ins, asmstr, pattern, itin>;
  def _1 : F2<?, ?, 1, outs, ins, !strconcat(asmstr,"!"), pattern>
  { let defs = [PSW]; }
}

multiclass BF3<dag outs, dag ins, string asmstr, list<dag> pattern> {
  def _0 : F3<?, ?, 0, outs, ins, asmstr, pattern, itin>;
  def _1 : F3<?, ?, 1, outs, ins, !strconcat(asmstr,"!"), pattern>
  { let defs = [PSW]; }
}

multiclass BF4<dag outs, dag ins, string asmstr, list<dag> pattern> {
  def _0 : F4<?, ?, 0, outs, ins, asmstr, pattern, itin>;
  def _1 : F4<?, ?, 1, outs, ins, !strconcat(asmstr,"!"), pattern>
  { let defs = [PSW]; }
}

multiclass BF5<dag outs, dag ins, string asmstr, list<dag> pattern> {
  def _0 : F5<?, ?, 0, outs, ins, asmstr, pattern, itin>;
  def _1 : F5<?, ?, 1, outs, ins, !strconcat(asmstr,"!"), pattern>
  { let defs = [PSW]; }
}


multiclass ArithLogicInstr<string mnem, SDNode OpNode> {
  def _F1 : BF1<(outs IntReg:$dst), (ins IntReg:$a, IntReg:$b),
                !strconcat(mnem, " $dst, $a, $b"),
                [(set IntReg:$dst, (OpNode IntReg:$a, IntReg:$b))]>;

  def _F2 : BF2<(outs IntReg:$dst), (ins IntReg:$a, imm11:$b),
                !strconcat(mnem, " $dst, $a, $b"),
                [(set IntReg:$dst, (OpNode IntReg:$a, immSExt11:$b))]>;

  def _F3 : BF3<(outs IntReg:$dst), (ins immZero:$z, IntReg:$b),
                !strconcat(mne, " $dst, %zero, $b"),
                [(set IntReg:$dst, (OpNode immZero:$z, IntReg:$b))]>;

  def _F4 : BF4<(outs IntReg:$dst), (ins IntReg:$dst, IntReg:$b),
                !strconcat(mnem, " $dst, $a, $b"),
                [(set IntReg:$dst, (OpNode IntReg:$dst, IntReg:$b))]>;

  def _F5 : BF5<(outs IntReg:$dst), (ins IntReg:$a, imm17:$b),
                !strconcat(mnem, " $dst, $a, $b"),
                [(set IntReg:$dst, (OpNode IntReg:$a, immSExt17:$b))]>;
}

multiclass ArithInstrRev<string mnem, SDNode OpNode> {
  def _F2 : BF2<(outs IntReg:$dst), (ins IntReg:$a, imm11:$b),
                !strconcat(mnem, " $dst, $a, $b"),
                [(set IntReg:$dst, (OpNode immSExt11:$b, IntReg:$a))]>;

  def _F5 : BF5<(outs IntReg:$dst), (ins IntReg:$a, imm17:$b),
                !strconcat(mnem, " $dst, $a, $b"),
                [(set IntReg:$dst, (OpNode immSExt17:$b, IntReg:$a))]>;
}

class LoadInstr<string mnem> :
    BF1<(outs IntReg:$dst), (ins mem:$addr),
        !strconcat(mnem, "$dst, [$addr]"),
        [(set IntReg:$dst, (load addr:$addr))]> {

  let canFoldAsLoad = 1;
  let hasDelaySlot = 1;
}

class StoreInstr<string mnem> :
  BF1<(outs), (ins IntReg:$dst, mem:$addr),
      !strconcat(mnem, " [$addr], $dst"),
      [(store IntReg:$dst, addr:$addr)], IIStore>;



//===----------------------------------------------------------------------===//
// Pseudo instructions
//===----------------------------------------------------------------------===//


// As stack alignment is always done with addiu, we need a 16-bit immediate
let Defs = [SP], Uses = [SP] in {
def ADJCALLSTACKDOWN : RiscoPseudo<(outs), (ins uimm16:$amt),
                                  "!ADJCALLSTACKDOWN $amt",
                                  [(callseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : RiscoPseudo<(outs), (ins uimm16:$amt1, uimm16:$amt2),
                                  "!ADJCALLSTACKUP $amt1",
                                  [(callseq_end timm:$amt1, timm:$amt2)]>;
}

//===----------------------------------------------------------------------===//
// Instruction definition
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// RiscoI Instructions
//===----------------------------------------------------------------------===//

def NOP : RiscoInstr<0,0,0,(outs),(ins),"nop",[]>;

let isCommutable = 1 in {
 defm ADD : ArithLogicInstr<"add", add>;
 defm AND : ArithLogicInstr<"and", and>;
 defm OR  : ArithLogicInstr<"or", or>;
 defm XOR : ArithLogicInstr<"xor", xor>;
}

defm SUB  : ArithLogicInstr<"sub", sub>;
defm SUBR : ArithInstrRev<"subr", sub>;

defm SLL  : ArithLogicInstr<"sll", shl>;
defm SRL  : ArithLogicInstr<"srl", srl>;
defm SRA  : ArithLogicInstr<"sra", sra>;

def LD    : LoadInstr<"ld">;
def ST    : StoreInstr<"st">;

















/// Arithmetic Instructions (ALU Immediate)
def ADDiu   : ArithI<0x09, "addiu", add, simm16, immSExt16>;
def ADDi    : ArithOverflowI<0x08, "addi",  add, simm16, immSExt16>;
def SLTi    : SetCC_I<0x0a, "slti", setlt, simm16, immSExt16>;
def SLTiu   : SetCC_I<0x0b, "sltiu", setult, simm16, immSExt16>;
def ANDi    : LogicI<0x0c, "andi", and>;
def ORi     : LogicI<0x0d, "ori",  or>;
def XORi    : LogicI<0x0e, "xori",  xor>;
def LUi     : LoadUpper<0x0f, "lui">;

/// Arithmetic Instructions (3-Operand, R-Type)
def ADDu    : ArithR<0x00, 0x21, "addu", add, IIAlu>;
def SUBu    : ArithR<0x00, 0x23, "subu", sub, IIAlu>;
def ADD     : ArithOverflowR<0x00, 0x20, "add">;
def SUB     : ArithOverflowR<0x00, 0x22, "sub">;
def SLT     : SetCC_R<0x00, 0x2a, "slt", setlt>;
def SLTu    : SetCC_R<0x00, 0x2b, "sltu", setult>;
def AND     : LogicR<0x24, "and", and>;
def OR      : LogicR<0x25, "or",  or>;
def XOR     : LogicR<0x26, "xor", xor>;
def NOR     : LogicNOR<0x00, 0x27, "nor">;

/// Shift Instructions
def SLL     : LogicR_shift_imm<0x00, "sll", shl>;
def SRL     : LogicR_shift_imm<0x02, "srl", srl>;
def SRA     : LogicR_shift_imm<0x03, "sra", sra>;
def SLLV    : LogicR_shift_reg<0x04, "sllv", shl>;
def SRLV    : LogicR_shift_reg<0x06, "srlv", srl>;
def SRAV    : LogicR_shift_reg<0x07, "srav", sra>;

/// Load and Store Instructions
def LB      : LoadM<0x20, "lb",  sextloadi8>;
def LBu     : LoadM<0x24, "lbu", zextloadi8>;
def LH      : LoadM<0x21, "lh",  sextloadi16>;
def LHu     : LoadM<0x25, "lhu", zextloadi16>;
def LW      : LoadM<0x23, "lw",  load>;
def SB      : StoreM<0x28, "sb", truncstorei8>;
def SH      : StoreM<0x29, "sh", truncstorei16>;
def SW      : StoreM<0x2b, "sw", store>;

/// Jump and Branch Instructions
def J       : JumpFJ<0x02, "j">;
def JR      : JumpFR<0x00, 0x08, "jr">;
def JAL     : JumpLink<0x03, "jal">;
def JALR    : JumpLinkReg<0x00, 0x09, "jalr">;
def BEQ     : CBranch<0x04, "beq", seteq>;
def BNE     : CBranch<0x05, "bne", setne>;

let rt=1 in
  def BGEZ  : CBranchZero<0x01, "bgez", setge>;

let rt=0 in {
  def BGTZ  : CBranchZero<0x07, "bgtz", setgt>;
  def BLEZ  : CBranchZero<0x07, "blez", setle>;
  def BLTZ  : CBranchZero<0x01, "bltz", setlt>;
}

def BGEZAL  : BranchLink<"bgezal">;
def BLTZAL  : BranchLink<"bltzal">;

let isReturn=1, isTerminator=1, hasDelaySlot=1,
    isBarrier=1, hasCtrlDep=1, rs=0, rt=0, shamt=0 in
  def RET : FR <0x00, 0x02, (outs), (ins IntReg:$target),
                "jr\t$target", [(RiscoRet IntReg:$target)], IIBranch>;

/// Multiply and Divide Instructions.
let Defs = [HI, LO] in {
  def MULT    : MulDiv<0x18, "mult", IIImul>;
  def MULTu   : MulDiv<0x19, "multu", IIImul>;
  def DIV     : MulDiv<0x1a, "div", IIIdiv>;
  def DIVu    : MulDiv<0x1b, "divu", IIIdiv>;
}

let Defs = [HI] in
  def MTHI  : MoveToLOHI<0x11, "mthi">;
let Defs = [LO] in
  def MTLO  : MoveToLOHI<0x13, "mtlo">;

let Uses = [HI] in
  def MFHI  : MoveFromLOHI<0x10, "mfhi">;
let Uses = [LO] in
  def MFLO  : MoveFromLOHI<0x12, "mflo">;

/// Sign Ext In Register Instructions.
let Predicates = [HasSEInReg] in {
  let shamt = 0x10, rs = 0 in
    def SEB : SignExtInReg<0x21, "seb", i8>;

  let shamt = 0x18, rs = 0 in
    def SEH : SignExtInReg<0x20, "seh", i16>;
}

/// Count Leading
let Predicates = [HasBitCount] in {
  let rt = 0 in
    def CLZ : CountLeading<0b010110, "clz", ctlz>;
}

/// Byte Swap
let Predicates = [HasSwap] in {
  let shamt = 0x3, rs = 0 in
    def WSBW : ByteSwap<0x20, "wsbw">;
}

/// Conditional Move
def MIPS_CMOV_ZERO  : PatLeaf<(i32 0)>;
def MIPS_CMOV_NZERO : PatLeaf<(i32 1)>;

let Predicates = [HasCondMov], Constraints = "$F = $dst" in {
  def MOVN : CondMov<0x0a, "movn", MIPS_CMOV_NZERO>;
  def MOVZ : CondMov<0x0b, "movz", MIPS_CMOV_ZERO>;
}

/// No operation
let addr=0 in
  def NOP   : FJ<0, (outs), (ins), "nop", [], IIAlu>;

// FrameIndexes are legalized when they are operands from load/store
// instructions. The same not happens for stack address copies, so an
// add op with mem ComplexPattern is used and the stack address copy
// can be matched. It's similar to Sparc LEA_ADDRi
def LEA_ADDiu : EffectiveAddress<"addiu\t$dst, ${addr:stackloc}">;

// MADD*/MSUB* are not part of RiscoI either.
//def MADD    : MArithR<0x00, "madd">;
//def MADDU   : MArithR<0x01, "maddu">;
//def MSUB    : MArithR<0x04, "msub">;
//def MSUBU   : MArithR<0x05, "msubu">;

// MUL is a assembly macro in the current used ISAs. In recent ISA's
// it is a real instruction.
//def MUL   : ArithR<0x1c, 0x02, "mul", mul, IIImul>;

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

