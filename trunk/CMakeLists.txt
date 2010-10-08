set(LLVM_TARGET_DEFINITIONS Risco.td)

tablegen(RiscoGenRegisterInfo.h.inc -gen-register-desc-header)
tablegen(RiscoGenRegisterNames.inc -gen-register-enums)
tablegen(RiscoGenRegisterInfo.inc -gen-register-desc)
tablegen(RiscoGenInstrNames.inc -gen-instr-enums)
tablegen(RiscoGenInstrInfo.inc -gen-instr-desc)
tablegen(RiscoGenAsmWriter.inc -gen-asm-writer)
tablegen(RiscoGenDAGISel.inc -gen-dag-isel)
tablegen(RiscoGenCallingConv.inc -gen-callingconv)
tablegen(RiscoGenSubtarget.inc -gen-subtarget)

add_llvm_target(RiscoCodeGen
  RiscoDelaySlotFiller.cpp
  RiscoInstrInfo.cpp
  RiscoISelDAGToDAG.cpp
  RiscoISelLowering.cpp
  RiscoMCAsmInfo.cpp
  RiscoRegisterInfo.cpp
  RiscoSubtarget.cpp
  RiscoTargetMachine.cpp
  RiscoTargetObjectFile.cpp
  RiscoSelectionDAGInfo.cpp
  )
