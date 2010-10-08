include_directories(
  ${CMAKE_CURRENT_BINARY_DIR}/..
  ${CMAKE_CURRENT_SOURCE_DIR}/..
  )

add_llvm_library(LLVMRiscoAsmPrinter
  RiscoAsmPrinter.cpp
  )
add_dependencies(LLVMRiscoAsmPrinter RiscoCodeGenTable_gen)
