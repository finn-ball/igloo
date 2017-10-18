`ifndef CHIP8_VH
 
 `define CHIP8_VH

 `define C8_REG_WIDTH         8
 `define C8_REG_DEPTH         16

 `define C8_STACK_WIDTH       8
 `define C8_STACK_DEPTH       48
 
 `define C8_MEM_WIDTH         8
 `define C8_MEM_DEPTH         4096

 `define C8_INTERPRETER_DEPTH 512

 `define C8_DISPLAY_WIDTH     64
 `define C8_DISPLAY_HEIGHT    32

 `define C8_CLS 16'h00E0
 `define C8_RET 16'h00EE

`endif
