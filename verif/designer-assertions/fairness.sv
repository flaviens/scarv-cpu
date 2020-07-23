
//
// module: design_assertions_fairness
//
//  Contains fairness assumptions for the core so that the designer
//  assertions environment "plays fair".
//
module design_assertions_fairness (

input  wire                 g_clk        , // Global clock
input  wire                 g_resetn     , // Global active low sync reset.

input  wire                 int_ext      , // hardware interrupt
              
input  wire                 imem_req     , // Memory request
input  wire [         31:0] imem_addr    , // Memory request address
input  wire                 imem_wen     , // Memory request write enable
input  wire [          3:0] imem_strb    , // Memory request write strobe
input  wire [         31:0] imem_wdata   , // Memory write data.
input  wire                 imem_gnt     , // Memory response valid
input  wire                 imem_err     , // Memory response error
input  wire [         31:0] imem_rdata   , // Memory response read data

input  wire                 dmem_req     , // Memory request
input  wire [         31:0] dmem_addr    , // Memory request address
input  wire                 dmem_wen     , // Memory request write enable
input  wire [          3:0] dmem_strb    , // Memory request write strobe
input  wire [         31:0] dmem_wdata   , // Memory write data.
input  wire                 dmem_gnt     , // Memory response valid
input  wire                 dmem_err     , // Memory response error
input  wire [         31:0] dmem_rdata   , // Memory response read data

input  wire                 trs_valid    , // Instruction trace valid
input  wire [         31:0] trs_instr    , // Instruction trace data
input  wire [         XL:0] trs_pc         // Instruction trace PC

);

//
// Common core parameters and constants.
`include "frv_common.svh"

//
// Assume that we start in reset.
initial assume(g_resetn == 1'b0);

endmodule
