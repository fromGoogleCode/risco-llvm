//===-- RiscoISelLowering.cpp - Risco DAG Lowering Implementation ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the interfaces that Risco uses to lower LLVM code into a
// selection DAG.
//
//===----------------------------------------------------------------------===//

#include "RiscoISelLowering.h"
#include "RiscoTargetMachine.h"
#include "RiscoMachineFunctionInfo.h"

#include "llvm/Function.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/ADT/VectorExtras.h"
#include "llvm/Support/ErrorHandling.h"
using namespace llvm;


//===----------------------------------------------------------------------===//
// Calling Convention Implementation
//===----------------------------------------------------------------------===//

#include "RiscoGenCallingConv.inc"


SDValue RiscoTargetLowering::
LowerReturn(SDValue Chain,
        CallingConv::ID CallConv, bool isVarArg,
        const SmallVectorImpl<ISD::OutputArg> &Outs,
        const SmallVectorImpl<SDValue> &OutVals,
        DebugLoc dl, SelectionDAG &DAG) const
{

  // CCValAssign - represent the assignment of the return value to locations.
  SmallVector<CCValAssign, 16 > RVLocs;

  // CCState - Info about the registers and stack slot.
  CCState CCInfo(CallConv, isVarArg, DAG.getTarget(),
          RVLocs, *DAG.getContext());

  // Analize return values.
  CCInfo.AnalyzeReturn(Outs, RetCC_Risco32);

  // If this is the first return lowered for this function, add the regs to the
  // liveout set for the function.
  if (DAG.getMachineFunction().getRegInfo().liveout_empty()) {
    for (unsigned i = 0; i != RVLocs.size(); ++i)
      if (RVLocs[i].isRegLoc())
        DAG.getMachineFunction().getRegInfo().addLiveOut(RVLocs[i].getLocReg());
  }

  SDValue Flag;

  // Copy the result values into the output registers.
  for (unsigned i = 0; i != RVLocs.size(); ++i) {
    CCValAssign &VA = RVLocs[i];
    assert(VA.isRegLoc() && "Can only return in registers!");

    Chain = DAG.getCopyToReg(Chain, dl, VA.getLocReg(),
            OutVals[i], Flag);

    // Guarantee that all emitted copies are stuck together with flags.
    Flag = Chain.getValue(1);
  }

  if (Flag.getNode())
    return DAG.getNode(RIISD::RET_FLAG, dl, MVT::Other, Chain, Flag);
  return DAG.getNode(RIISD::RET_FLAG, dl, MVT::Other, Chain);
}


SDValue RiscoTargetLowering::
LowerFormalArguments(SDValue Chain,
        CallingConv::ID CallConv, bool isVarArg,
        const SmallVectorImpl<ISD::InputArg> &Ins,
        DebugLoc dl, SelectionDAG &DAG,
        SmallVectorImpl<SDValue> &InVals) const
{

  MachineFunction &mFunction = DAG.getMachineFunction();
  MachineRegisterInfo &RegInfo = mFunction.getRegInfo();
  RiscoMachineFunctionInfo *FuncInfo = mFunction.getInfo<RiscoMachineFunctionInfo>();

  // Assign locations to all of the incoming arguments.
  SmallVector<CCValAssign, 16 > ArgLocs;
  CCState CCInfo(CallConv, isVarArg, getTargetMachine(),
          ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeFormalArguments(Ins, CC_Risco32);

  static const unsigned ArgRegs[] = {
    Risco::A0, Risco::A1, Risco::A2, Risco::A3, Risco::A4
  };

  const unsigned *CurArgReg = ArgRegs, *ArgRegEnd = ArgRegs + 5;
  unsigned ArgOffset = 68;

  for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i) {
    SDValue ArgValue;
    CCValAssign &VA = ArgLocs[i];

    // FIXME: We ignore the register assignments of AnalyzeFormalArguments
    // because it doesn't know how to split a double into two i32 registers.
    EVT ObjectVT = VA.getValVT();
    switch (ObjectVT.getSimpleVT().SimpleTy) {
      default: llvm_unreachable("Unhandled argument type!");
      case MVT::i1:
      case MVT::i8:
      case MVT::i16:
      case MVT::i32:
        if (!Ins[i].Used) { // Argument is dead.
          if (CurArgReg < ArgRegEnd) ++CurArgReg;
          InVals.push_back(DAG.getUNDEF(ObjectVT));
        } else if (CurArgReg < ArgRegEnd) { // Lives in an incoming GPR
          unsigned VReg = RegInfo.createVirtualRegister(&Risco::IntRegRegClass);
          mFunction.getRegInfo().addLiveIn(*CurArgReg++, VReg);
          SDValue Arg = DAG.getCopyFromReg(Chain, dl, VReg, MVT::i32);
          InVals.push_back(Arg);
        } else {
          int FrameIdx = mFunction.getFrameInfo()->CreateFixedObject(4, ArgOffset,
                  true);

          SDValue FIPtr = DAG.getFrameIndex(FrameIdx, MVT::i32);

          SDValue Load = DAG.getLoad(MVT::i32, dl, Chain, FIPtr, MachinePointerInfo(),
                  false, false, 0);
          InVals.push_back(Load);
        }

        ArgOffset += 4;
        break;
    }

    return Chain;
  }
}


SDValue RiscoTargetLowering::
LowerCall(SDValue Chain, SDValue Callee,
          CallingConv::ID CallConv, bool isVarArg,
          bool &isTailCall,
          const SmallVectorImpl<ISD::OutputArg> &Outs,
          const SmallVectorImpl<SDValue> &OutVals,
          const SmallVectorImpl<ISD::InputArg> &Ins,
          DebugLoc dl, SelectionDAG &DAG,
          SmallVectorImpl<SDValue> &InVals) const
{
  // Risco target does not yet support tail call optimization.
  isTailCall = false;

  (void)CC_Risco32;

  // Count the size of the outgoing arguments.
  unsigned ArgsSize = 0;
  for (unsigned i = 0, e = Outs.size(); i != e; ++i) {
    switch (Outs[i].VT.getSimpleVT().SimpleTy) {
      default: llvm_unreachable("Unknown value type!");
      case MVT::i1:
      case MVT::i8:
      case MVT::i16:
      case MVT::i32:
        ArgsSize += 4;
        break;
    }
  }
  
  if (ArgsSize > 4*5)
    ArgsSize -= 4*5;    // Space for first 5 arguments is prereserved.
  else
    ArgsSize = 0;

  Chain = DAG.getCALLSEQ_START(Chain, DAG.getIntPtrConstant(ArgsSize, true));

  SmallVector<std::pair<unsigned, SDValue>, 8> RegsToPass;
  SmallVector<SDValue, 8> MemOpChains;

  static const unsigned ArgRegs[] = {
    Risco::A0, Risco::A1, Risco::A2, Risco::A3, Risco::A4
  };
  unsigned ArgOffset = 68;

  for (unsigned i = 0, e = Outs.size(); i != e; ++i) {
    SDValue Val = OutVals[i];
    EVT ObjectVT = Outs[i].VT;
    SDValue ValToStore(0, 0);

    unsigned ObjSize;

    switch (ObjectVT.getSimpleVT().SimpleTy) {
    default: llvm_unreachable("Unhandled argument type!");
    case MVT::i32:
      ObjSize = 4;

      if (RegsToPass.size() >= 5) {
        ValToStore = Val;
      } else {
        RegsToPass.push_back(std::make_pair(ArgRegs[RegsToPass.size()], Val));
      }
      break;
    }

    if (ValToStore.getNode()) {
      SDValue StackPtr = DAG.getRegister(Risco::SP, MVT::i32);
      SDValue PtrOff = DAG.getConstant(ArgOffset, MVT::i32);
      PtrOff = DAG.getNode(ISD::ADD, dl, MVT::i32, StackPtr, PtrOff);
      MemOpChains.push_back(DAG.getStore(Chain, dl, ValToStore,
                                         PtrOff, MachinePointerInfo(),
                                         false, false, 0));
    }
    ArgOffset += ObjSize;
  }

  // Emit all stores, make sure the occur before any copies into physregs.
  if (!MemOpChains.empty())
    Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other,
                        &MemOpChains[0], MemOpChains.size());

  // Build a sequence of copy-to-reg nodes chained together with token
  // chain and flag operands which copy the outgoing args into registers.
  // The InFlag in necessary since all emited instructions must be
  // stuck together.
  SDValue InFlag;
  for (unsigned i = 0, e = RegsToPass.size(); i != e; ++i) {
    Chain = DAG.getCopyToReg(Chain, dl, RegsToPass[i].first,
                             RegsToPass[i].second, InFlag);
    InFlag = Chain.getValue(1);
  }

  // If the callee is a GlobalAddress node (quite common, every direct call is)
  // turn it into a TargetGlobalAddress node so that legalize doesn't hack it.
  // Likewise ExternalSymbol -> TargetExternalSymbol.
  
  if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee)) {
    Callee = DAG.getTargetGlobalAddress(G->getGlobal(), dl, MVT::i32);
  }
  else if (ExternalSymbolSDNode *E = dyn_cast<ExternalSymbolSDNode>(Callee)) {
    Callee = DAG.getTargetExternalSymbol(E->getSymbol(), MVT::i32);
  }

  std::vector<EVT> NodeTys;
  NodeTys.push_back(MVT::Other);   // Returns a chain
  NodeTys.push_back(MVT::Flag);    // Returns a flag for retval copy to use.
  SDValue Ops[] = { Chain, Callee, InFlag };
  Chain = DAG.getNode(RIISD::CALL, dl, NodeTys, Ops, InFlag.getNode() ? 3 : 2);
  InFlag = Chain.getValue(1);

  Chain = DAG.getCALLSEQ_END(Chain, DAG.getIntPtrConstant(ArgsSize, true),
                             DAG.getIntPtrConstant(0, true), InFlag);
  InFlag = Chain.getValue(1);

  // Assign locations to each value returned by this call.
  SmallVector<CCValAssign, 16> RVLocs;
  CCState RVInfo(CallConv, isVarArg, DAG.getTarget(),
                 RVLocs, *DAG.getContext());

  RVInfo.AnalyzeCallResult(Ins, RetCC_Risco32);

  // Copy all of the result registers out of their specified physreg.
  for (unsigned i = 0; i != RVLocs.size(); ++i) {
    Chain = DAG.getCopyFromReg(Chain, dl, RVLocs[i].getLocReg(),
                               RVLocs[i].getValVT(), InFlag).getValue(1);
    InFlag = Chain.getValue(2);
    InVals.push_back(Chain.getValue(0));
  }

  return Chain;
}



//===----------------------------------------------------------------------===//
// TargetLowering Implementation
//===----------------------------------------------------------------------===//

/// IntCondCCodeToICC - Convert a DAG integer condition code to a Risco ICC
/// condition.
static RICC::CondCodes IntCondCCodeToICC(ISD::CondCode CC) {
  switch (CC) {
  default: llvm_unreachable("Unknown integer condition code!");
  case ISD::SETEQ:  return RICC::ICC_EQ;
  case ISD::SETNE:  return RICC::ICC_NE;
  case ISD::SETLT:  return RICC::ICC_LT;
  case ISD::SETGT:  return RICC::ICC_GT;
  case ISD::SETLE:  return RICC::ICC_LE;
  case ISD::SETGE:  return RICC::ICC_GE;
  case ISD::SETULT: return RICC::ICC_LT;
  case ISD::SETULE: return RICC::ICC_LE;
  case ISD::SETUGT: return RICC::ICC_GT;
  case ISD::SETUGE: return RICC::ICC_GE;
  }
}


RiscoTargetLowering::RiscoTargetLowering(TargetMachine &TM)
  : TargetLowering(TM, new TargetLoweringObjectFileELF()) {

  setSelectIsExpensive();

  // Set up the register classes.
  addRegisterClass(MVT::i32, Risco::IntRegRegisterClass);

  // Risco doesn't have i1 sign extending load
  setLoadExtAction(ISD::SEXTLOAD, MVT::i1, Promote);

  // Custom legalize GlobalAddress nodes into LO/HI parts.
  setOperationAction(ISD::GlobalAddress, MVT::i32, Custom);
  setOperationAction(ISD::GlobalTLSAddress, MVT::i32, Custom);
  setOperationAction(ISD::ConstantPool , MVT::i32, Custom);

  // Risco doesn't have sext_inreg, replace them with shl/sra
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i16, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i8 , Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1 , Expand);

  // Risco doesn't have BRCOND either, it has BR_CC.
  setOperationAction(ISD::BRCOND, MVT::Other, Expand);
  setOperationAction(ISD::BRIND, MVT::Other, Expand);
  setOperationAction(ISD::BR_JT, MVT::Other, Expand);
  setOperationAction(ISD::BR_CC, MVT::i32, Custom);

  setOperationAction(ISD::STACKSAVE         , MVT::Other, Expand);
  setOperationAction(ISD::STACKRESTORE      , MVT::Other, Expand);
  setOperationAction(ISD::DYNAMIC_STACKALLOC, MVT::i32  , Custom);

  setStackPointerRegisterToSaveRestore(Risco::SP);

  computeRegisterProperties();
}

const char *RiscoTargetLowering::getTargetNodeName(unsigned Opcode) const {
  switch (Opcode) {
  default: return 0;
  case RIISD::CMPICC:     return "RIISD::CMPICC";

  case RIISD::JMPICC:     return "RIISD::JMPICC";

  case RIISD::HI:         return "RIISD::HI";
  case RIISD::LO:         return "RIISD::LO";
  
  case RIISD::CALL:       return "RIISD::CALL";
  case RIISD::RET_FLAG:   return "RIISD::RET_FLAG";
  }
}

/// isMaskedValueZeroForTargetNode - Return true if 'Op & Mask' is known to
/// be zero. Op is expected to be a target specific node. Used by DAG
/// combiner.
void RiscoTargetLowering::
computeMaskedBitsForTargetNode(const SDValue Op,
                               const APInt &Mask,
                               APInt &KnownZero,
                               APInt &KnownOne,
                               const SelectionDAG &DAG,
                               unsigned Depth) const
{
  KnownZero = KnownOne = APInt(Mask.getBitWidth(), 0);   // Don't know anything.
}


// Look at LHS/RHS/CC and see if they are a lowered setcc instruction.  If so
// set LHS/RHS and SPCC to the LHS/RHS of the setcc and SPCC to the condition.
static void LookThroughSetCC(SDValue &LHS, SDValue &RHS,
                             ISD::CondCode CC, unsigned &SPCC)
{ }


SDValue RiscoTargetLowering::
LowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const
{
  const GlobalValue *GV = cast<GlobalAddressSDNode>(Op)->getGlobal();

  // FIXME there isn't really any debug info here
  DebugLoc dl = Op.getDebugLoc();
  SDValue GA = DAG.getTargetGlobalAddress(GV, dl, MVT::i32);
  SDValue Hi = DAG.getNode(RIISD::HI, dl, MVT::i32, GA);
  SDValue Lo = DAG.getNode(RIISD::LO, dl, MVT::i32, GA);

  return DAG.getNode(ISD::ADD, dl, MVT::i32, Lo, Hi);
}


SDValue RiscoTargetLowering::
LowerConstantPool(SDValue Op, SelectionDAG &DAG) const
{
  ConstantPoolSDNode *N = cast<ConstantPoolSDNode>(Op);

  // FIXME there isn't really any debug info here
  DebugLoc dl = Op.getDebugLoc();
  const Constant *C = N->getConstVal();
  SDValue CP = DAG.getTargetConstantPool(C, MVT::i32, N->getAlignment());
  SDValue Hi = DAG.getNode(RIISD::HI, dl, MVT::i32, CP);
  SDValue Lo = DAG.getNode(RIISD::LO, dl, MVT::i32, CP);

  return DAG.getNode(ISD::ADD, dl, MVT::i32, Lo, Hi);
}


static SDValue LowerBR_CC(SDValue Op, SelectionDAG &DAG)
{
  SDValue Chain = Op.getOperand(0);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(1))->get();
  SDValue LHS = Op.getOperand(2);
  SDValue RHS = Op.getOperand(3);
  SDValue Dest = Op.getOperand(4);
  DebugLoc dl = Op.getDebugLoc();
  unsigned Opc, RICC;

  // Get the condition flag.
  SDValue CompareFlag;
  
  std::vector<EVT> VTs;
  VTs.push_back(MVT::i32);
  VTs.push_back(MVT::Flag);
  SDValue Ops[2] = { LHS, RHS };

  CompareFlag = DAG.getNode(RIISD::CMPICC, dl, VTs, Ops, 2).getValue(1);

  RICC = IntCondCCodeToICC(CC);
  Opc = RIISD::JMPICC;
  
  return DAG.getNode(Opc, dl, MVT::Other, Chain, Dest,
                     DAG.getConstant(RICC, MVT::i32), CompareFlag);
}


static SDValue LowerDYNAMIC_STACKALLOC(SDValue Op, SelectionDAG &DAG)
{
  SDValue Chain = Op.getOperand(0);  // Legalize the chain.
  SDValue Size  = Op.getOperand(1);  // Legalize the size.
  DebugLoc dl = Op.getDebugLoc();

  unsigned SPReg = Risco::SP;
  SDValue SP = DAG.getCopyFromReg(Chain, dl, SPReg, MVT::i32);
  SDValue NewSP = DAG.getNode(ISD::SUB, dl, MVT::i32, SP, Size); // Value
  Chain = DAG.getCopyToReg(SP.getValue(1), dl, SPReg, NewSP);    // Output chain

  // The resultant pointer is actually 16 words from the bottom of the stack,
  // to provide a register spill area.
  SDValue NewVal = DAG.getNode(ISD::ADD, dl, MVT::i32, NewSP,
                                 DAG.getConstant(96, MVT::i32));
  SDValue Ops[2] = { NewVal, Chain };
  return DAG.getMergeValues(Ops, 2, dl);
}


SDValue RiscoTargetLowering::
LowerOperation(SDValue Op, SelectionDAG &DAG) const
{
  switch (Op.getOpcode()) {
    default: llvm_unreachable("Should not custom lower this!");

    case ISD::GlobalAddress:      return LowerGlobalAddress(Op, DAG);
    case ISD::ConstantPool:       return LowerConstantPool(Op, DAG);
    case ISD::BR_CC:              return LowerBR_CC(Op, DAG);
    case ISD::DYNAMIC_STACKALLOC: return LowerDYNAMIC_STACKALLOC(Op, DAG);
  }
}


//===----------------------------------------------------------------------===//
//                         Risco Inline Assembly Support
//===----------------------------------------------------------------------===//

/// getConstraintType - Given a constraint letter, return the type of
/// constraint it is for this target.
RiscoTargetLowering::ConstraintType
RiscoTargetLowering::getConstraintType(const std::string &Constraint) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    default:  break;
    case 'r': return C_RegisterClass;
    }
  }

  return TargetLowering::getConstraintType(Constraint);
}

std::pair<unsigned, const TargetRegisterClass*>
RiscoTargetLowering::getRegForInlineAsmConstraint(const std::string &Constraint,
                                                  EVT VT) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    case 'r':
      return std::make_pair(0U, Risco::IntRegRegisterClass);
    }
  }

  return TargetLowering::getRegForInlineAsmConstraint(Constraint, VT);
}

std::vector<unsigned> RiscoTargetLowering::
getRegClassForInlineAsmConstraint(const std::string &Constraint,
                                  EVT VT) const {
  if (Constraint.size() != 1)
    return std::vector<unsigned>();

  switch (Constraint[0]) {
  default: break;
  case 'r':
    return make_vector<unsigned>(Risco::S0, Risco::S1, Risco::S2, Risco::S3,
                                 Risco::S4, Risco::S5, Risco::S6, Risco::S7,
                                 Risco::T0, Risco::T1, Risco::T2, Risco::T3,
                                 Risco::T4, Risco::T5, Risco::T7, 0);
  }

  return std::vector<unsigned>();
}

bool
RiscoTargetLowering::isOffsetFoldingLegal(const GlobalAddressSDNode *GA) const {
  // The Risco target isn't yet aware of offsets.
  return false;
}

/// getFunctionAlignment - Return the Log2 alignment of this function.
unsigned RiscoTargetLowering::getFunctionAlignment(const Function *) const {
  return 2;
}
