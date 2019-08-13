
`include "xcfi_macros.sv"
`include "xcfi_macros_packed.vh"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [ 1:0] pw          = `INSTR_PACK_WIDTH;

`PACK_WIDTH_ARITH_OPERATION_RESULT(-,0)

 // From the PACK_WIDTH_ARITH_OPERATION_RESULT macro.
wire [31:0] insn_result = result;

wire                  spec_valid       = rvfi_valid && dec_xc_psub;
wire                  spec_trap        = 1'b0   ;
wire [         4 : 0] spec_rs1_addr    = `FIELD_RS1_ADDR;
wire [         4 : 0] spec_rs2_addr    = `FIELD_RS2_ADDR;
wire [         4 : 0] spec_rs3_addr    = 0;
wire [         4 : 0] spec_rd_addr     = `FIELD_RD_ADDR;
wire [XLEN   - 1 : 0] spec_rd_wdata    = spec_rd_addr ? insn_result : {XLEN{1'b0}};
wire [XLEN   - 1 : 0] spec_pc_wdata    = rvfi_pc_rdata + 4;
wire [XLEN   - 1 : 0] spec_mem_addr    = 0;
wire [XLEN/8 - 1 : 0] spec_mem_rmask   = 0;
wire [XLEN/8 - 1 : 0] spec_mem_wmask   = 0;
wire [XLEN   - 1 : 0] spec_mem_wdata   = 0;

endmodule

