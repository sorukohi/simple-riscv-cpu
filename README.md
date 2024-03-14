# simple-riscv-cpu
Repository has a HDL simple RISC-V single-cycle CPU on SystemVerilog. It's implemented on the basic ISA RV32I with an additional Zicsr extension, as well as the privileged mret instruction. The unit contains a Load/Store Unit, Interruption controller, Control and Status Register unit, as well as modules for communicating with the peripherals.
Testbanches, constraints file, some design files are taken from [this course](https://github.com/MPSU/APS/tree/master/Labs).
