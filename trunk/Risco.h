//===-- Risco.h - Top-level interface for Risco representation --*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in the LLVM
// Risco back-end.
//
//===----------------------------------------------------------------------===//

#ifndef TARGET_RISCO_H
#define TARGET_RISCO_H

#include "llvm/Support/ErrorHandling.h"
#include "llvm/Target/TargetMachine.h"
#include <cassert>

namespace llvm {
  class FunctionPass;
  class RiscoTargetMachine;
  class formatted_raw_ostream;

  FunctionPass *createRiscoISelDag(RiscoTargetMachine &TM);

  extern Target TheRiscoTarget;
  extern Target TheRiscoSimulatorTarget;

} // end namespace llvm;

// Defines symbolic names for Risco registers.  This defines a mapping from
// register name to register number.
//
#include "RiscoGenRegisterNames.inc"

// Defines symbolic names for the Risco instructions.
//
#include "RiscoGenInstrNames.inc"


namespace llvm {
  // Enums corresponding to Risco condition codes, both icc's and fcc's.  These
  // values must be kept in sync with the ones in the .td file.
  namespace RICC {
    enum CondCodes {
       ICC_TR  = 0b11111,
       ICC_NS  = 0b10001,
       ICC_CS  = 0b10010,
       ICC_OS  = 0b10100,
       ICC_ZS  = 0b11000,
       ICC_GE  = 0b10011,
       ICC_GT  = 0b10110,
       ICC_EQ  = 0b11100,

       ICC_FL  = 0b00000,
       ICC_NN  = 0b00001,
       ICC_NC  = 0b00010,
       ICC_NO  = 0b00100,
       ICC_NZ  = 0b01000,
       ICC_LT  = 0b00011,
       ICC_LE  = 0b00110,
       ICC_NE  = 0b01100
    };
  }
  
  inline static const char *RISCOCondCodeToString(RICC::CondCodes CC) {
    switch (CC) {
      default: llvm_unreachable("Unknown condition code");

      case RICC::ICC_TR : return "tr";
      case RICC::ICC_NS : return "ns";
      case RICC::ICC_CS : return "cs";
      case RICC::ICC_OS : return "os";
      case RICC::ICC_ZS : return "zs";
      case RICC::ICC_GE : return "ge";
      case RICC::ICC_GT : return "gt";
      case RICC::ICC_EQ : return "eq";

      case RICC::ICC_FL : return "fl";
      case RICC::ICC_NN : return "nn";
      case RICC::ICC_NC : return "nc";
      case RICC::ICC_NO : return "no";
      case RICC::ICC_NZ : return "nz";
      case RICC::ICC_LT : return "lt";
      case RICC::ICC_LE : return "le";
      case RICC::ICC_NE : return "ne";
    }       
  }
}  // end namespace llvm
#endif
