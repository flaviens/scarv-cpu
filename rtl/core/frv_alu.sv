
//
// module: frv_alu 
//
//  ALU for the execute stage.
//  - add/sub/bitwise/shift
//
module frv_alu (

input  wire [   XL:0]   opr_a   , // Input operand A
input  wire [   XL:0]   opr_b   , // Input operand B
input  wire [    4:0]   shamt   , // Shift amount.

input  wire             op_add  , // Select output of adder
input  wire             op_sub  , // Subtract opr_a from opr_b else add
input  wire             op_xor  , // Select XOR operation result
input  wire             op_or   , // Select OR
input  wire             op_and  , //        AND
input  wire             op_slt  , // Set less than
input  wire             op_sltu , //                Unsigned
input  wire             op_srl  , // Shift right logical
input  wire             op_sll  , // Shift left logical
input  wire             op_sra  , // Shift right arithmetic
input  wire             op_ror   ,// Rotate right
input  wire             op_rol   ,// Rotate left
input  wire             op_pack  ,// Pack
input  wire             op_packh ,// "
input  wire             op_packu ,// "
input  wire             op_grev  ,// Generalized reverse
input  wire             op_shfl  ,// Shuffle
input  wire             op_unshfl,// Unshuffle
input  wire             op_xnor  ,// 
input  wire             op_orn   ,// 
input  wire             op_andn  ,// 

output wire [   XL:0]   add_out , // Result of adding opr_a and opr_b
output wire             cmp_eq  , // Result of opr_a == opr_b
output wire             cmp_lt  , // Result of opr_a <  opr_b
output wire             cmp_ltu , // Result of opr_a <  opr_b

output wire [   XL:0]   result    // Operation result

);

// Common core parameters and constants
`include "frv_common.svh"

//
// Miscellaneous
// ------------------------------------------------------------

assign cmp_eq               = opr_a == opr_b;

//
// Add / Sub
// ------------------------------------------------------------

wire [XL:0] addsub_rhs      = op_sub ? ~opr_b : opr_b               ;

wire [XL:0] addsub_result   = opr_a + addsub_rhs + {{XL{1'b0}},op_sub};
assign      add_out         = addsub_result                         ;

//
// SLT / SLTU
// TODO: Re-use addsub for SLT comparison.
// ------------------------------------------------------------

wire        slt_signed      = $signed(opr_a) < $signed(opr_b);

wire        slt_unsigned    = $unsigned(opr_a) < $unsigned(opr_b);

wire        slt_lsbu        = slt_unsigned ;

wire        slt_lsb         = slt_signed   ;

assign      cmp_ltu         = slt_lsbu;
assign      cmp_lt          = slt_lsb;

wire [XL:0] slt_result      = {{XL{1'b0}}, op_slt ? slt_lsb : slt_lsbu};

//
// Bitwise Operations
// ------------------------------------------------------------

wire [XL:0] opr_b_n         = op_xnor || op_orn || op_andn ? ~opr_b : opr_b;

wire [XL:0] xor_output      = opr_a ^ opr_b_n;
wire [XL:0]  or_output      = opr_a | opr_b_n;
wire [XL:0] and_output      = opr_a & opr_b_n;

wire [XL:0] bitwise_result  = {XLEN{op_xor || op_xnor}} &  xor_output |
                              {XLEN{op_or  || op_orn }} &   or_output |
                              {XLEN{op_and || op_andn}} &  and_output ;
//
// Pack*
// ------------------------------------------------------------

wire [XL:0] pack_output     = {       opr_b[15: 0], opr_a[15: 0]};
wire [XL:0] packu_output    = {       opr_b[31:16], opr_a[31:16]};
wire [XL:0] packh_output    = {16'b0, opr_b[ 7: 0], opr_a[ 7: 0]};

wire [XL:0] pack_result     = {XLEN{op_pack }} & pack_output    |
                              {XLEN{op_packh}} & packh_output   |
                              {XLEN{op_packu}} & packu_output   ;

//
// Shifts and rotates
// ------------------------------------------------------------

wire [XL:0] shift_in_r  = opr_a;
wire [XL:0] shift_in_l  ;

wire        shift_abit  = opr_a[XL];

wire        sr_left     = op_sll || op_rol ;
wire        sr_right    = op_srl || op_ror || op_sra;
wire        rotate      = op_rol || op_ror ;

localparam SW = (XLEN*2) - 1;

wire [XL:0] shift_in_lo = sr_left ? shift_in_l : shift_in_r;

wire [XL:0] shift_in_hi = rotate  ? (shift_in_lo     )  :
                          op_sra  ? {XLEN{shift_abit}}  :
                                     32'b0              ;

wire [SW:0] shift_in    = {shift_in_hi, shift_in_lo     };

wire [SW:0] shift_out   = shift_in    >> shamt          ;
wire [XL:0] shift_out_r = shift_out[XL:0]               ;
wire [XL:0] shift_out_l ;

genvar i;
generate for(i = 0; i < XLEN; i = i + 1) begin
    assign shift_in_l [i] = shift_in_r [XL-i];
    assign shift_out_l[i] = shift_out_r[XL-i];
end endgenerate

wire [XL:0] shift_result=
    {XLEN{sr_left }} &  shift_out_l |
    {XLEN{sr_right}} &  shift_out_r ;

//
// GREV
// ------------------------------------------------------------

// Control bits for grev and [un]shfl
wire [ 4:0] ctrl       = opr_b[4:0];

reg  [XL:0] grev_result;

`define GREV_STEP(M1, M2, CTRL, SHF)                                        \
  grev_result =                                                             \
    ctrl[CTRL] ? ((grev_result & M1) << SHF) | ((grev_result & M2) >> SHF) :\
                   grev_result                                             ;

always @(*) begin
    grev_result = opr_a;
    `GREV_STEP(32'h55555555, 32'hAAAAAAAA, 0,  1)
    `GREV_STEP(32'h33333333, 32'hCCCCCCCC, 1,  2)
    `GREV_STEP(32'h0F0F0F0F, 32'hF0F0F0F0, 2,  4)
    `GREV_STEP(32'h00FF00FF, 32'hFF00FF00, 3,  8)
    `GREV_STEP(32'h0000FFFF, 32'hFFFF0000, 4, 16)
end

`undef GREV_STEP

//
// SHFL and UNSHFL
// ------------------------------------------------------------

`define SHFL_STEP(CTRL,SRC, ML, MR, N)                                      \
  SRC    =                                                                  \
    ctrl[CTRL] ? ((SRC  & ~(ML|MR)) | ((SRC << N) & ML) | ((SRC>>N) & MR)) :\
                   SRC

reg  [XL:0] shfl_result  ;
reg  [XL:0] unshfl_result;

always @(*) begin
    shfl_result = opr_a;
    `SHFL_STEP(3, shfl_result, 32'h00FF0000, 32'h0000FF00, 8);
    `SHFL_STEP(2, shfl_result, 32'h0F000F00, 32'h00F000F0, 4);
    `SHFL_STEP(1, shfl_result, 32'h30303030, 32'h0C0C0C0C, 2);
    `SHFL_STEP(0, shfl_result, 32'h44444444, 32'h22222222, 1);
    
    unshfl_result = opr_a;
    `SHFL_STEP(0, unshfl_result, 32'h44444444, 32'h22222222, 1);
    `SHFL_STEP(1, unshfl_result, 32'h30303030, 32'h0C0C0C0C, 2);
    `SHFL_STEP(2, unshfl_result, 32'h0F000F00, 32'h00F000F0, 4);
    `SHFL_STEP(3, unshfl_result, 32'h00FF0000, 32'h0000FF00, 8);
end


`undef SHFL_STEP

//
// Result multiplexing
// ------------------------------------------------------------

wire sel_addsub = op_add || op_sub  ;
wire sel_slt    = op_slt || op_sltu ;
wire sel_shift  = op_sll || op_sra  || op_srl || rotate;

assign result =
                         bitwise_result             |
                         pack_result                |
    {XLEN{op_grev   }} & grev_result                |
    {XLEN{op_shfl   }} & shfl_result                |
    {XLEN{op_unshfl }} & unshfl_result              |
    {XLEN{sel_addsub}} & addsub_result              |
    {XLEN{sel_slt   }} & slt_result                 |
    {XLEN{sel_shift }} & shift_result               ;

endmodule

