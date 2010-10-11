//=====-- RiscoMCAsmInfo.h - Risco asm properties -------------*- C++ -*--====//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the RiscoMCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef RISCOTARGETASMINFO_H
#define RISCOTARGETASMINFO_H

#include "llvm/ADT/StringRef.h"
#include "llvm/MC/MCAsmInfo.h"

namespace llvm {
  class Target;

  struct RiscoELFMCAsmInfo : public MCAsmInfo {
    explicit RiscoELFMCAsmInfo(const Target &T, StringRef TT);
  };

} // namespace llvm

#endif
