An implementation of a Risco processor backend for the current LLVM release (2.9, svn trunk).

The assembly language grammar and instruction set definitions are taken from the risco-simulator.


# README #


## Instalação ##

### risco-as ###
  1. Executa `make`
  1. Fazer links de `risco-as/dist/.../risco-as` e `risco-as/risco-peep-opt` para o `$PATH`

### risco-simulator ###
  1. Executa `make`
  1. Fazer link de `risco-simulator/dist/.../risco-simulator` para o `$PATH`

### risco-llvm ###
  1. Baixar a última versão do código fonte do LLVM a partir do repositório SVN
  1. Sobreescrever os arquivos `CFGPrinter.cpp` e `MachineFunction.cpp` com as versões disponibilizadas no pacote `risco-llvm-full`
  1. Copiar o diretório `Risco` para o subdiretório `lib/Target/` do LLVM
  1. Copiar o diretório `RiscoPlugins` para o subdiretório `lib/Transforms/` do LLVM
  1. Seguir as instruções de compilação normal do LLVM (segundo a sua documentação)
  1. Seguir as instruções de instalação normal do LLVM (segundo a sua documentação)

### risco-cfg ###
  1. Fazer link de `risco-llvm/risco-c` para o `$PATH`


## Compilar um programa ##

  1. Executa `risco-c programa.cpp`. São gerados os arquivos em linguagem de montagem e o executável final


## Simular a execução de um programa ##

  1. Executa `risco-simulator programa.bin`


## Gerar o CFG-FULL de cada rotina de um programa ##

  1. Executa `risco-cfg fullcfg programa.ll`


## Visualizar o CFG-FULL de uma rotina ##

  1. Executa `xdot cfg.dot`