##===- lib/Target/Risco/Makefile ----------------------------*- Makefile -*-===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
##===----------------------------------------------------------------------===##

LEVEL = ../../..
LIBRARYNAME = LLVMRiscoCodeGen
TARGET = Risco

# Make sure that tblgen is run, first thing.
BUILT_SOURCES = RiscoGenRegisterInfo.h.inc RiscoGenRegisterNames.inc \
                RiscoGenRegisterInfo.inc RiscoGenInstrNames.inc \
                RiscoGenInstrInfo.inc RiscoGenAsmWriter.inc \
                RiscoGenDAGISel.inc RiscoGenCallingConv.inc \
                RiscoGenSubtarget.inc

DIRS = AsmPrinter TargetInfo

include $(LEVEL)/Makefile.common

