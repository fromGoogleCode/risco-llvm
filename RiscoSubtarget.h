//=====-- RiscoSubtarget.h - Define Subtarget for the RISCO ----*- C++ -*-====//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the RISCO specific subclass of TargetSubtarget.
//
//===----------------------------------------------------------------------===//

#ifndef RISCO_SUBTARGET_H
#define RISCO_SUBTARGET_H

#include "llvm/Target/TargetSubtarget.h"
#include <string>

namespace llvm {

class RiscoSubtarget : public TargetSubtarget {
public:
  RiscoSubtarget(const std::string &TT, const std::string &FS);
  
  /// ParseSubtargetFeatures - Parses features string setting specified 
  /// subtarget options.  Definition of function is auto generated by tblgen.
  std::string ParseSubtargetFeatures(const std::string &FS,
                                     const std::string &CPU);
};

} // end namespace llvm

#endif
