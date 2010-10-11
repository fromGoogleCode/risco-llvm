//===-- RiscoMCAsmInfo.cpp - Risco asm properties -------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the RiscoMCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "RiscoMCAsmInfo.h"
using namespace llvm;


RiscoELFMCAsmInfo::
RiscoELFMCAsmInfo(const Target &T, StringRef TT)
{
  CommentString = ";";
  AllowPeriodsInName = false;
  AscizDirective = ".asciiz";
  Data32bitsDirective = ".word";
  Data64bitsDirective = NULL;
  GlobalDirective = ".global";
  ExternDirective = ".extern";
  HasSetDirective = false;
}
