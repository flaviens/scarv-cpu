
//
// module: frv_masked_shuffle
//
//  Performs a permutation of a 32-bit word. Used to shuffle one
//  share of each input/result of a masked operation.
//  This mitigates accidental un-masking through muxing.
//
module frv_masked_shuffle #(
parameter LEN   = 32,
parameter CONST = 32'h0
)(
input  wire [LEN-1:0] i  ,
input  wire           en ,
input  wire           fwd,
output wire [LEN-1:0] o
);

wire [LEN-1:0] rev_in   ;
wire [LEN-1:0] rev_out  ;

wire [LEN-1:0] const_in  =  fwd ? CONST: {LEN{1'b0}};
wire [LEN-1:0] const_out = !fwd ? CONST: {LEN{1'b0}};

assign rev_in   = i ^ const_in;

genvar J;
for (J = 0; J < LEN; J = J+1) begin
    assign rev_out[J] = rev_in[(LEN-1)-J];
end

assign o        = en ? rev_out ^ const_out: i;


endmodule


//
// module: frv_masked_alu
//
//  Responsible for performing masking operations.
//
module frv_masked_alu (

input  wire        g_clk            , // Global clock
input  wire        g_resetn         , // Synchronous, active low reset.

input  wire        valid            , // Inputs valid
input  wire        flush            , // Flush the masked ALU.

input  wire        op_b2a           , // Binary to arithmetic mask covert
input  wire        op_a2b           , // Arithmetic to binary mask convert
input  wire        op_b_mask        , // Binary mask
input  wire        op_b_remask      , // Binary remask
input  wire        op_a_mask        , // Arithmetic mask
input  wire        op_a_remask      , // Arithmetic remask
input  wire        op_b_not         , // Binary masked not
input  wire        op_b_and         , // Binary masked and
input  wire        op_b_ior         , // Binary masked or
input  wire        op_b_xor         , // Binary masked xor
input  wire        op_b_add         , // Binary masked addition
input  wire        op_b_sub         , // Binary masked subtraction
input  wire        op_b_srli        , // Shift right, shamt in msk_rs2_s0
input  wire        op_b_slli        , // Shift left, shamt in msk_rs2_s0
input  wire        op_b_rori        , // Shift right, shamt in msk_rs2_s0
input  wire        op_a_add         , // Masked arithmetic add
input  wire        op_a_sub         , // Masked arithmetic subtract.
input  wire        op_f_mul         , // Finite field multiply
input  wire        op_f_aff         , // Affine transform

input  wire        prng_update      , // Force the PRNG to update.

input  wire [XL:0] rs1_s0           , // RS1 Share 0
input  wire [XL:0] rs1_s1           , // RS1 Share 1
input  wire [XL:0] rs2_s0           , // RS2 Share 0
input  wire [XL:0] rs2_s1           , // RS2 Share 1

output wire        ready            , // Outputs ready
output wire [XL:0] mask             , // The mask, used for verification only.
output wire [XL:0] rd_s0            , // Output share 0
output wire [XL:0] rd_s1              // Output share 1

);

// Common core parameters and constants
`include "frv_common.vh"

//
// Masking ISE - Use a TRNG (1) or a PRNG (0)
parameter MASKING_ISE_TRNG    = 1'b0;

// Masking ISE - Use a Threshold Implementation (1) or non-TI (0)
parameter MASKING_ISE_TI      = 1'b1;

// Use a fast implementaiton of the masking ISE instructions.
parameter MASKING_ISE_FAST    = 1'b1;

// Enable finite-field instructions (or not).
parameter ENABLE_FAFF = 1;
parameter ENABLE_FMUL = 1;

// PRNG for masking, mask refreshing
wire          prng_req;
reg  [31:0]   prng;
wire        n_prng_lsb = prng[31] ~^ prng[21] ~^ prng[ 1] ~^ prng[ 0];
wire [31:0] n_prng     = {prng[31-1:0], n_prng_lsb};
// Process for updating the LFSR.
always @(posedge g_clk) begin
    if(!g_resetn)      prng <= 32'h6789ABCD;
    else if(prng_req )  prng <= n_prng;
end
assign prng_req = ready || (prng_update && (!op_b2a));

wire [XL:0] gs_0;
wire [XL:0] mxor0, mxor1;
wire [XL:0] mand0, mand1;

wire [XL:0] madd0, madd1;

wire [ 2:0] seq_cnt;
wire        addsub_ena;
wire        madd_rdy;

wire 	    mlogic_ena;
wire        mlogic_rdy;

// BOOL NOT: Boolean masked NOT 
wire [XL:0] mnot0, mnot1;
wire        mnot_rdy = op_b_not;
assign mnot0 =  rs1_s0;
assign mnot1 = ~rs1_s1;

wire        nrs2_opt= (op_b_ior||op_b_sub);
wire [XL:0] nrs2_s0 =  rs2_s0;
wire [XL:0] nrs2_s1 = ~rs2_s1;

// B2A PRE: reuse the boolean masked add/sub to execute Boolean masking to arithmetic masking instruction
// Expected:rs0 ^ rs1 = rd0 - rd1
// BoolAdd: (a0 ^ a1) + (b0 ^ b1) = (a+b)^z ^ z st. s = a+b
//=>
// a0 = rs0;  a1=rs1;     b0 = prng ; b1=0
//rd0 = s0 ^ s1;         rd1 = prng
wire [XL:0] b2a_a0 = rs1_s0;
wire [XL:0] b2a_a1 = rs1_s1;
wire [XL:0] b2a_b0 = prng;
wire [XL:0] b2a_b1 = {XLEN{1'b0}};

// A2B PRE: reuse the boolean masked add/sub to execute arithmetic masking to Boolean masking instruction
// expected:rs0 - rs1 = rd0 ^ rd1
// BoolSub: (a0 ^ a1) - (b0 ^ b1) = s0 ^ s1  st. s = a-b  
//=>
// a0 = rs0;  a1= 0;      b0 = prng; b1= rs1 ^ prng
//rd0 = s0;              rd1 = s1

// Refreshing the share 1 before converting to avoid collision
wire [XL:0] a2b_a0 = rs1_s0;
wire [XL:0] a2b_a1 = {XLEN{1'b0}};
wire [XL:0] a2b_b0 = prng;
wire [XL:0] a2b_b1 = ~rs1_s1 ^ prng;  // the NOT operation to perform BoolSub


// Operand multiplexing 
wire [XL:0] op_a0, op_a1, op_b0, op_b1;

assign op_a0 =  rs1_s0;
assign op_a1 =  op_b_ior ? mnot1   :
                op_b2a   ? b2a_a1  :
                op_a2b   ? a2b_a1  :
                           rs1_s1  ;

assign op_b0 =  op_b2a   ? b2a_b0  :
                op_a2b   ? a2b_b0  :
                           rs2_s0  ;
assign op_b1 =  nrs2_opt ? nrs2_s1 :
                op_b2a   ? b2a_b1  : 
                op_a2b   ? a2b_b1  :
                           rs2_s1  ; 

// BOOL XOR; BOOL AND: Boolean masked logic executes BoolXor; BoolAnd;
msklogic #(
    .MASKING_ISE_TI(MASKING_ISE_TI)
) msklogic_ins (
    .g_resetn(  g_resetn),
    .g_clk(     g_clk), 
    .ena(       mlogic_ena), 
    .i_gs(      n_prng), 
    .i_a0(      op_a0), 
    .i_a1(      op_a1), 
    .i_b0(      op_b0),
    .i_b1(      op_b1), 
    .o_xor0(    mxor0),
    .o_xor1(    mxor1), 
    .o_and0(    mand0),
    .o_and1(    mand1),  
    .o_gs(      gs_0),
    .rdy(       mlogic_rdy)
);

// SUB OPT: execute the operations at line 5 & 6 in the BoolSub algorithm.
wire        sub     =  op_b_sub || op_a2b;
wire        u_0     =  mand0[0] ^ (mxor0[0] && sub);
wire        u_1     =  mand1[0] ^ (mxor1[0] && sub);
wire [31:0] s_mand0 = {mand0[31:1],u_0};
wire [31:0] s_mand1 = {mand1[31:1],u_1};

// BOOL ADD/SUB ITERATION and BOOL ADD/SUB POST 
mskaddsub   
#(  .MASKING_ISE_TI(MASKING_ISE_TI))
mskaddsub_ins(
    .g_resetn(  g_resetn),
    .g_clk(     g_clk),    
    .flush(     flush),
    .ena(       addsub_ena), 
    .sub(       sub),
    .i_gs(      gs_0), 
    .mxor0(     mxor0),
    .mxor1(     mxor1), 
    .mand0(   s_mand0),
    .mand1(   s_mand1),  
    .o_s0(      madd0), 
    .o_s1(      madd1), 
    .rdy(       madd_rdy));

// Control unit for Boolean masked calculations
wire dologic     = (!flush) && (op_b_xor || op_b_and || op_b_ior);
wire op_b_addsub = (!flush) && (op_b_add || op_b_sub || op_b2a   || op_a2b  );

mskalu_ctl mskaluctl_ins (
    .g_resetn   (g_resetn               ),
    .g_clk      (g_clk                  ),
    .flush      (flush                  ),
    .valid      (valid                  ),
    .dologic    (dologic||op_b_addsub   ), 
    .doaddsub   (op_b_addsub            ), 
    .mlogic_rdy (mlogic_rdy             ),
    .madd_rdy   (madd_rdy               ),
    .mlogic_ena (mlogic_ena             ), 
    .addsub_ena (addsub_ena             )
);

// IOR POST: reuse BOOL AND to execute BoolIor
wire [XL:0] mior0 =  mand0;
wire [XL:0] mior1 = ~mand1;

// B2A POST: calculate the ouput of Bool2Arith from the output of BoolAdd 
// calculate output only if the b2a instruction is executed
// to avoid unintentionally unmasking the output of masked add/sub module
wire op_b2a_latched;  //prevent any glitches on the op_b2a  
FF_Nb ff_dob2a(
    .g_resetn(  g_resetn        ), 
    .g_clk(     g_clk           ), 
    .ena(       valid           ), 
    .din(       op_b2a          ), 
    .dout(      op_b2a_latched  )
);

wire [XL:0] madd0_gated = (op_b2a_latched)? madd0 : prng;
wire [XL:0] madd1_gated = (op_b2a_latched)? madd1 : prng;
wire [XL:0] mb2a0 = madd0_gated ^ madd1_gated;   
wire [XL:0] mb2a1 = prng;

// SHIFT/ ROTATE: Boolean masked shift/rotate
// Share 0 input gets reversed, so pick shamt from high 5 bits of rs2_s0
wire [4:0] shamt = rs2_s0[4:0];
    //op_shr ? {rs2_s0[27],rs2_s0[28],rs2_s0[29],rs2_s0[30],rs2_s0[31]} : 5'b0;

wire op_shr  = op_b_srli || op_b_slli || op_b_rori;
wire shr_rdy = op_shr;

wire [XL:0]  mshr0, mshr1;
shfrot shfrpt_ins0(
    .s(      rs1_s0     ), 
    .shamt(  shamt      ), // Shift amount 
    .rp (    prng       ), // random padding
    .srli(op_b_srli     ), // Shift  right
    .slli(op_b_slli     ), // Shift  left
    .rori(op_b_rori     ), // Rotate right
    .r(      mshr0      )  
);

shfrot shfrpt_ins1(
    .s(      rs1_s1     ), 
    .shamt(  shamt      ), // Shift amount 
    .rp (    prng       ), // random padding
    .srli(op_b_srli     ), // Shift  right
    .slli(op_b_slli     ), // Shift  left
    .rori(op_b_rori     ), // Rotate right
    .r(      mshr1      )  
);

// MASK	/ REMASK: Boolean masking and remasking
wire opmask = (!flush) &  op_b_mask;   //masking operation
wire remask = (!flush) &  op_b_remask;

wire op_msk = opmask | remask;
wire [XL:0] rmask0, rmask1;
wire        msk_rdy;

generate 
    if (MASKING_ISE_TI == 1'b1) begin : masking_TI

        wire [XL:0] bm_a0 = rs1_s0 ^ prng;

        reg  [XL:0] m_a0_reg;
        always @(posedge g_clk) 
            if (!g_resetn)          m_a0_reg <= {XLEN{1'b0}};
            else if (opmask|remask) m_a0_reg <= bm_a0;

        wire [XL:0] xm_a0 = m_a0_reg;

        wire [XL:0] brm_a0 = xm_a0 ^ rs1_s1;

        assign      rmask0 = (opmask)? m_a0_reg: brm_a0;
        assign      rmask1 = (opmask | remask)? prng : {XLEN{1'b0}};

        reg  mask_done;
        always @(posedge g_clk) 
            if (!g_resetn)                {mask_done} <= 1'd0;
            else if (op_msk & ~mask_done) {mask_done} <= 1'b1;
            else                          {mask_done} <= 1'd0;
        assign msk_rdy = mask_done;

    end else begin                    : masking_non_TI

        assign rmask0  =            rs1_s0 ^ prng;
        assign rmask1  = (remask)? (rs1_s1 ^ prng):
                         /* mask*/           prng;
        assign msk_rdy = op_msk;
    end
endgenerate

// ARITH ADD/SUB: arithmetic masked add and subtraction 
wire [XL:0]  amsk0, amsk1;
arithmask arithmask_ins(
    .i_a0(rs1_s0),
    .i_a1(rs1_s1),
    .i_b0(rs2_s0),
    .i_b1(rs2_s1),
    .i_gs(  prng),
    .mask(      op_a_mask  ),
    .remask(    op_a_remask),
    .doadd(     op_a_add   ),
    .dosub(     op_a_sub   ),
    .o_r0( amsk0),
    .o_r1( amsk1)
);
wire         op_amsk  = op_a_mask || op_a_remask ||op_a_add || op_a_sub;
wire         amsk_rdy = op_amsk;
// FAFF: Boolean masked affine transformation in field gf(2^8) for AES
wire [XL:0]  mfaff0, mfaff1;
wire [XL:0]  mfmul0, mfmul1;

generate if (ENABLE_FAFF) begin : FAFF_ENABLED
mskfaff makfaff_ins(	
    .i_a0(rs1_s0),
    .i_a1(rs1_s1),
    .i_mt({rs2_s1, rs2_s0}),
    .i_gs(prng),
    .o_r0(mfaff0),
    .o_r1(mfaff1)
); 
end else begin : FAFF_DISABLED
    assign mfaff0 = 32'b0;
    assign mfaff1 = 32'b0;
end endgenerate

// FMUL: Boolean masked multiplication in field gf(2^8) for AES
generate if(ENABLE_FMUL) begin: FMUL_ENABLED
mskfmul mskfmul_ins(	
    .i_a0(rs1_s0),
    .i_a1(rs1_s1),
    .i_b0(rs2_s0),
    .i_b1(rs2_s1),
    .i_gs(prng),
    .o_r0(mfmul0),
    .o_r1(mfmul1)
);
end else begin : FMUL_DISABLED
    assign mfmul0 = 32'b0;
    assign mfmul1 = 32'b0;
end endgenerate

// OUTPUT MUX: gather and multiplexing results
assign rd_s0 = {XLEN{op_b_not}} &  (n_prng ^ mnot0) |
               {XLEN{op_b_xor}} &  (n_prng ^ mxor0) |
               {XLEN{op_b_and}} &  mand0 |
               {XLEN{op_b_ior}} &  mior0 |
               {XLEN{op_shr  }} &  mshr0 |
               {XLEN{op_b_add}} &  madd0 |
               {XLEN{op_b_sub}} &  madd0 |
               {XLEN{op_a2b  }} &  madd0 |
               {XLEN{op_b2a  }} &  mb2a0 | 
               {XLEN{op_msk  }} &  rmask0|
               {XLEN{op_amsk }} &  amsk0 |
               {XLEN{op_f_mul}} &  mfmul0|
               {XLEN{op_f_aff}} &  mfaff0;

assign rd_s1 = {XLEN{op_b_not}} &  (n_prng ^ mnot1) |
               {XLEN{op_b_xor}} &  (n_prng ^ mxor1) |
               {XLEN{op_b_and}} &  mand1 |
               {XLEN{op_b_ior}} &  mior1 |
               {XLEN{op_shr  }} &  mshr1 |
               {XLEN{op_b_add}} &  madd1 |
               {XLEN{op_b_sub}} &  madd1 |
               {XLEN{op_a2b  }} &  madd1 |
               {XLEN{op_b2a  }} &  mb2a1 |
               {XLEN{op_msk  }} &  rmask1|
               {XLEN{op_amsk }} &  amsk1 |
               {XLEN{op_f_mul}} &  mfmul1|
               {XLEN{op_f_aff}} &  mfaff1;


assign ready = mnot_rdy || (dologic && mlogic_rdy) ||
               madd_rdy || shr_rdy || msk_rdy      ||
               amsk_rdy || op_f_mul|| op_f_aff ;
assign mask  = prng;

endmodule


module mskalu_ctl(
input  wire      g_resetn, g_clk, flush,
input  wire      valid,
input  wire      dologic, doaddsub, mlogic_rdy, madd_rdy, 
output wire      mlogic_ena,
output wire      addsub_ena
);

localparam S_IDL = 2'b00;
localparam S_LOG = 2'b01;        //executing logical    instructions
localparam S_ART = 2'b10;        //executing arithmetic instructions

wire dologic_valid  = dologic && valid;
wire doaddsub_valid = doaddsub&& valid;

reg [1:0] ctl_state;
always @(posedge g_clk) begin
  if (!g_resetn)    ctl_state <= S_IDL;
  else if (flush)   ctl_state <= S_IDL;
  else begin
    case (ctl_state)
        S_IDL :     ctl_state <= 
                            (dologic_valid) ? 
                           ((mlogic_rdy)    ? 
                           ((doaddsub_valid)? S_ART : S_IDL)
                                                    : S_LOG) 
                                                    : S_IDL; 
        S_LOG :     ctl_state <= (doaddsub_valid)?  S_ART : S_IDL;
        S_ART :     ctl_state <= (madd_rdy)?  S_IDL : S_ART;
        default:    ctl_state <= S_IDL;
    endcase	
  end					
end
assign    mlogic_ena =  dologic_valid  && (ctl_state == S_IDL);
assign    addsub_ena =  doaddsub_valid && ((mlogic_rdy && (ctl_state == S_IDL)) | (ctl_state != S_IDL));

endmodule


//Arithmetic masking operations
module arithmask(
input  [31:0] i_a0,
input  [31:0] i_a1,
input  [31:0] i_b0,
input  [31:0] i_b1,
input  [31:0] i_gs,
input         mask,
input         remask,
input         doadd,
input         dosub,
output [31:0] o_r0,
output [31:0] o_r1
);

wire [32:0]  amadd0, amadd1;
wire [31:0]  opr_lhs_0, opr_rhs_0;
wire [31:0]  opr_lhs_1, opr_rhs_1;
wire         ci;

assign opr_lhs_0 =             i_a0 ;
assign opr_rhs_0 =  ( doadd)?  i_b0 :
                    ( dosub)? ~i_b0 :
              /*mask|remask*/  i_gs ;
assign opr_lhs_1 =  ( ~mask)?  i_a1 :
                     /*mask*/  i_gs ;
assign opr_rhs_1 =  ( doadd)?  i_b1 :
                    ( dosub)? ~i_b1 :
                    (remask)?  i_gs :
                     /*mask*/ 32'd0 ;
assign ci = dosub;

assign amadd0 = {opr_lhs_0,1'b1} + {opr_rhs_0,ci};
assign amadd1 = {opr_lhs_1,1'b1} + {opr_rhs_1,ci};

assign o_r0 = amadd0[32:1];
assign o_r1 = amadd1[32:1];

endmodule


//Boolean masked multiplication in field gf(2^8) for AES
module mskfmul(	
input  [31:0] i_a0,
input  [31:0] i_a1,
input  [31:0] i_b0,
input  [31:0] i_b1,
input  [31:0] i_gs,
output [31:0] o_r0,
output [31:0] o_r1
);

wire [31:0] m00, m11, m01, m10;

gf256_mul mult0_b0 (.i_a(i_a0[ 7: 0]), .i_b(i_b0[ 7: 0]), .o_r(m00[ 7: 0]));
gf256_mul mult1_b0 (.i_a(i_a1[ 7: 0]), .i_b(i_b1[ 7: 0]), .o_r(m11[ 7: 0]));
gf256_mul mult2_b0 (.i_a(i_a0[ 7: 0]), .i_b(i_b1[ 7: 0]), .o_r(m01[ 7: 0]));
gf256_mul mult3_b0 (.i_a(i_a1[ 7: 0]), .i_b(i_b0[ 7: 0]), .o_r(m10[ 7: 0]));

gf256_mul mult0_b1 (.i_a(i_a0[15: 8]), .i_b(i_b0[15: 8]), .o_r(m00[15: 8]));
gf256_mul mult1_b1 (.i_a(i_a1[15: 8]), .i_b(i_b1[15: 8]), .o_r(m11[15: 8]));
gf256_mul mult2_b1 (.i_a(i_a0[15: 8]), .i_b(i_b1[15: 8]), .o_r(m01[15: 8]));
gf256_mul mult3_b1 (.i_a(i_a1[15: 8]), .i_b(i_b0[15: 8]), .o_r(m10[15: 8]));

gf256_mul mult0_b2 (.i_a(i_a0[23:16]), .i_b(i_b0[23:16]), .o_r(m00[23:16]));
gf256_mul mult1_b2 (.i_a(i_a1[23:16]), .i_b(i_b1[23:16]), .o_r(m11[23:16]));
gf256_mul mult2_b2 (.i_a(i_a0[23:16]), .i_b(i_b1[23:16]), .o_r(m01[23:16]));
gf256_mul mult3_b2 (.i_a(i_a1[23:16]), .i_b(i_b0[23:16]), .o_r(m10[23:16]));

gf256_mul mult0_b3 (.i_a(i_a0[31:24]), .i_b(i_b0[31:24]), .o_r(m00[31:24]));
gf256_mul mult1_b3 (.i_a(i_a1[31:24]), .i_b(i_b1[31:24]), .o_r(m11[31:24]));
gf256_mul mult2_b3 (.i_a(i_a0[31:24]), .i_b(i_b1[31:24]), .o_r(m01[31:24]));
gf256_mul mult3_b3 (.i_a(i_a1[31:24]), .i_b(i_b0[31:24]), .o_r(m10[31:24]));

(* keep="true" *)
wire [31:0] refresh = i_gs ^ m01 ^ m10;
 
assign o_r0 = m00 ^ i_gs;
assign o_r1 = m11 ^ refresh;

endmodule

//Boolean masked affine transformation in field gf(2^8) for AES
/* 
   i_a0, i_a1: 2 shares of 4-byte input
   i_mt      : 8 8-bit rows of 64-bit affine matrix. 
   i_gs      : guard share for refreshing
   o_r0, o_r1: 2 shares of 4-byte output
*/
module mskfaff(	
input  [31:0] i_a0,
input  [31:0] i_a1,
input  [63:0] i_mt,
input  [31:0] i_gs,
output [31:0] o_r0,
output [31:0] o_r1
);

wire [31:0] r0, r1;
gf256_aff atr0_b0 (.i_a(i_a0[ 7: 0]), .i_m(i_mt), .o_r(r0[ 7: 0]));
gf256_aff atr1_b0 (.i_a(i_a1[ 7: 0]), .i_m(i_mt), .o_r(r1[ 7: 0]));

gf256_aff atr0_b1 (.i_a(i_a0[15: 8]), .i_m(i_mt), .o_r(r0[15: 8]));
gf256_aff atr1_b1 (.i_a(i_a1[15: 8]), .i_m(i_mt), .o_r(r1[15: 8]));

gf256_aff atr0_b2 (.i_a(i_a0[23:16]), .i_m(i_mt), .o_r(r0[23:16]));
gf256_aff atr1_b2 (.i_a(i_a1[23:16]), .i_m(i_mt), .o_r(r1[23:16]));

gf256_aff atr0_b3 (.i_a(i_a0[31:24]), .i_m(i_mt), .o_r(r0[31:24]));
gf256_aff atr1_b3 (.i_a(i_a1[31:24]), .i_m(i_mt), .o_r(r1[31:24]));
 
assign o_r0 = i_gs ^ r0;
assign o_r1 = i_gs ^ r1;

endmodule
// Shift/rotate module to operate on each sharing with random pading
module shfrot(
input  [31:0] s    , // input share
input  [ 4:0] shamt, // Shift amount 
input  [31:0] rp   , // random padding
input         srli , // Shift  right
input         slli , // Shift  left
input         rori , // Rotate right

output [31:0] r      // ouput share
);

wire left = slli;
wire right= srli | rori;

wire [31:0] l0 =  s;

wire [31:0]  l1;
wire [31:0]  l2;
wire [31:0]  l4;
wire [31:0]  l8;
wire [31:0] l16;

wire         l1_rpr = (rori)? l0[   0] : rp[    0];
wire [ 1:0]  l2_rpr = (rori)? l1[ 1:0] : rp[ 2: 1];
wire [ 3:0]  l4_rpr = (rori)? l2[ 3:0] : rp[ 6: 3];
wire [ 7:0]  l8_rpr = (rori)? l4[ 7:0] : rp[14: 7];
wire [15:0] l16_rpr = (rori)? l8[15:0] : rp[30:15];
//
// Level 1 code - shift/rotate by 1.
wire [31:0] l1_left  = {l0[30:0], rp[31]};
wire [31:0] l1_right = {l1_rpr  , l0[31:1]};
  
wire l1_l  = left  && shamt[0];
wire l1_r  = right && shamt[0];
wire l1_n  =         !shamt[0];

assign l1  = {32{l1_l}} & l1_left  |
             {32{l1_r}} & l1_right |
             {32{l1_n}} & l0       ;

// Level 2 code - shift/rotate by 2..
wire [31:0] l2_left  = {l1[29:0], rp[30:29]};
wire [31:0] l2_right = {l2_rpr  , l1[31: 2]};
  
wire l2_l  = left  && shamt[1];
wire l2_r  = right && shamt[1];
wire l2_n  =         !shamt[1];

assign l2  = {32{l2_l}} & l2_left  |
             {32{l2_r}} & l2_right |
             {32{l2_n}} & l1       ;

// Level 3 code - shift/rotate by 4.
wire [31:0] l4_left  = {l2[27:0], rp[28:25]};
wire [31:0] l4_right = {l4_rpr  , l2[31: 4]};
  
wire l4_l  = left  && shamt[2];
wire l4_r  = right && shamt[2];
wire l4_n  =         !shamt[2];
assign l4  = {32{l4_l}} & l4_left  |
             {32{l4_r}} & l4_right |
             {32{l4_n}} & l2       ;

// Level 4 code - shift/rotate by 8.
wire [31:0] l8_left  = {l4[23:0], rp[24:17]};
wire [31:0] l8_right = {l8_rpr  , l4[31: 8]};
  
wire l8_l  = left  && shamt[3];
wire l8_r  = right && shamt[3];
wire l8_n  =         !shamt[3];

assign l8  = {32{l8_l}} & l8_left  |
             {32{l8_r}} & l8_right |
             {32{l8_n}} & l4       ;

// Level 5 code - shift/rotate by 16.
wire [31:0] l16_left  = {l8[15:0], rp[16: 1]};
wire [31:0] l16_right = {l16_rpr , l8[31:16]};
  
wire l16_l  = left  && shamt[4];
wire l16_r  = right && shamt[4];
wire l16_n  =         !shamt[4];

assign l16  = {32{l16_l}} & l16_left  |
              {32{l16_r}} & l16_right |
              {32{l16_n}} & l8        ;

// output
assign r = l16;

endmodule


module msklogic(
  input wire         g_resetn, g_clk, ena, 
  input wire  [31:0] i_gs,
  input wire  [31:0] i_a0,  i_a1, 
  input wire  [31:0] i_b0,  i_b1,
  output wire [31:0] o_xor0, o_xor1,
  output wire [31:0] o_and0, o_and1,
  output wire [31:0] o_gs,
  output wire        rdy
);

// Masking ISE - Use a Threshold Implementation (1) or non-TI (0)
parameter MASKING_ISE_TI      = 1'b0;

(* keep="true" *) 
wire [31:0] gs;
assign      gs = i_gs; 
assign    o_gs = i_a1; 

generate 
    if (MASKING_ISE_TI == 1'b1) begin : masking_TI
        wire [31:0] p0 = i_a0 ^ i_b0;
        wire [31:0] p1 = i_a1 ^ i_b1;

        FF_Nb #(.Nb(32)) ff_p0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(p0), .dout(o_xor0));
        FF_Nb #(.Nb(32)) ff_p1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(p1), .dout(o_xor1));

        wire [31:0] i_t0 = i_gs ^ (i_a0 & i_b0);
        wire [31:0] i_t1 = i_gs ^ (i_a0 & i_b1);
        wire [31:0] i_t2 = (i_a1 & i_b0);
        wire [31:0] i_t3 = (i_a1 & i_b1);

        wire [31:0] t0,t1;
        wire [31:0] t2,t3;
        FF_Nb #(.Nb(32)) ff_t0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_t0), .dout(t0));
        FF_Nb #(.Nb(32)) ff_t1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_t1), .dout(t1));
        FF_Nb #(.Nb(32)) ff_t2(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_t2), .dout(t2));
        FF_Nb #(.Nb(32)) ff_t3(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_t3), .dout(t3));

        assign o_and0 = t0 ^ t2;
        assign o_and1 = t1 ^ t3;
    end else begin                    : masking_non_TI
        assign o_xor0 = i_a0 ^ i_b0;
        assign o_xor1 = i_a1 ^ i_b1;  
    
        assign o_and0 = i_gs ^ (i_a0 & i_b1) ^ (i_a0 | ~i_b0);
        assign o_and1 = i_gs ^ (i_a1 & i_b1) ^ (i_a1 | ~i_b0);  
    end
endgenerate

generate 
    if (MASKING_ISE_TI == 1'b1) begin: masking_TI
        FF_Nb  ff_msklogic_rdy(.g_resetn(g_resetn), .g_clk(g_clk), .ena(1'b1), .din(ena), .dout(rdy));
    end else begin                   : masking_non_TI
        assign rdy = ena;
    end
endgenerate
endmodule

module mskaddsub(
    input wire         g_resetn, g_clk, flush, ena,
    input wire         sub,  // active to perform a-b
    input wire  [31:0] i_gs,
    input wire  [31:0] mxor0, mxor1,
    input wire  [31:0] mand0, mand1,
    output wire [31:0] o_s0, o_s1,
    output wire        rdy
);

// Masking ISE - Use a Threshold Implementation (1) or non-TI (0)
parameter MASKING_ISE_TI      = 1'b0;

wire [31:0] gs;
wire [31:0] p0, p1;
wire [31:0] g0, g1;

wire [31:0] gs_i;
wire [31:0] p0_i, p1_i;
wire [31:0] g0_i, g1_i;

reg  [ 2:0] seq_cnt;
always @(posedge g_clk)
  if (!g_resetn)    seq_cnt <=3'd1;
  else if (flush)   seq_cnt <=3'd1;
  else if (rdy)     seq_cnt <=3'd1;
  else if (ena)     seq_cnt <=seq_cnt + 1'b1;

wire ini = ena && (seq_cnt == 3'd1);

wire [31:0] o_s0_gated;
wire [31:0] o_s1_gated;

assign o_s0 = (rdy || seq_cnt == 3'd1) ? o_s0_gated : 32'b0;
assign o_s1 = (rdy || seq_cnt == 3'd1) ? o_s1_gated : 32'b0;

assign gs_i = (ini)?   i_gs : gs;
assign p0_i = (ini)?   mxor0: p0;
assign p1_i = (ini)?   mxor1: p1;
assign g0_i = (ini)?   mand0: g0;
assign g1_i = (ini)?   mand1: g1;
seq_process 
#(  .MASKING_ISE_TI(MASKING_ISE_TI))
seqproc_ins(
    .g_resetn(  g_resetn),
    .g_clk(     g_clk),
    .ena(       ena), 
    .i_gs(      gs_i), 
    .seq(       seq_cnt),  
    .i_pk0(     p0_i),
    .i_pk1(     p1_i),  
    .i_gk0(     g0_i),
    .i_gk1(     g1_i),   
    .o_pk0(     p0),
    .o_pk1(     p1), 
    .o_gk0(     g0),
    .o_gk1(     g1),  
    .o_gs(      gs));

postprocess posproc_ins(
    .sub(       sub),
    .i_pk0(     mxor0),
    .i_pk1(     mxor1), 
    .i_gk0(     g0),
    .i_gk1(     g1),
    .o_s0(      o_s0_gated),
    .o_s1(      o_s1_gated));

assign rdy = (seq_cnt==3'd6);
endmodule

module seq_process(
  input wire         g_resetn, g_clk, ena,
  input wire  [31:0] i_gs,
  input wire  [ 2:0] seq,

  input wire  [31:0] i_pk0, i_pk1,
  input wire  [31:0] i_gk0, i_gk1,
  output wire [31:0] o_pk0, o_pk1,
  output wire [31:0] o_gk0, o_gk1,

  output wire [31:0] o_gs
);

// Masking ISE - Use a Threshold Implementation (1) or non-TI (0)
parameter MASKING_ISE_TI      = 1'b0;

(* keep="true" *)  
wire [31:0] gs;
assign      gs = i_gs;
assign    o_gs = i_pk0;

reg [31:0] gkj0, gkj1;
reg [31:0] pkj0, pkj1;

always @(*) begin
  case (seq)
      3'b001: begin
                  gkj0 = {i_gk0[30:0],1'd0};
                  gkj1 = {i_gk1[30:0],1'd0};
                  pkj0 = {i_pk0[30:0],1'd0};
                  pkj1 = {i_pk1[30:0],1'd0};
               end
      3'b010 : begin
                  gkj0 = {i_gk0[29:0],2'd0};
                  gkj1 = {i_gk1[29:0],2'd0};                  
                  pkj0 = {i_pk0[29:0],2'd0};
                  pkj1 = {i_pk1[29:0],2'd0};
               end
      3'b011 : begin
                  gkj0 = {i_gk0[27:0],4'd0};
                  gkj1 = {i_gk1[27:0],4'd0};                  
                  pkj0 = {i_pk0[27:0],4'd0};
                  pkj1 = {i_pk1[27:0],4'd0};
               end
      3'b100 : begin
                  gkj0 = {i_gk0[23:0],8'd0};
                  gkj1 = {i_gk1[23:0],8'd0};                  
                  pkj0 = {i_pk0[23:0],8'd0};
                  pkj1 = {i_pk1[23:0],8'd0};
               end
      3'b101 : begin
                  gkj0 = {i_gk0[15:0],16'd0};
                  gkj1 = {i_gk1[15:0],16'd0};                  
                  pkj0 = {32'd0};
                  pkj1 = {32'd0};
               end
      default: begin
                  gkj0 = {32'd0};
                  gkj1 = {32'd0};                  
                  pkj0 = {32'd0};
                  pkj1 = {32'd0};
               end
   endcase
end

generate 
    if (MASKING_ISE_TI == 1'b1) begin : masking_TI
        wire [31:0] i_tg0 = i_gk0 ^ (gkj0 & i_pk0);
        wire [31:0] i_tg1 = i_gk1 ^ (gkj1 & i_pk0);
        wire [31:0] i_tg2 =         (gkj0 & i_pk1);
        wire [31:0] i_tg3 =         (gkj1 & i_pk1);

        wire tg0,tg1;
        wire tg2,tg3;
        FF_Nb #(.Nb(32)) ff_tg0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tg0), .dout(tg0));
        FF_Nb #(.Nb(32)) ff_tg1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tg1), .dout(tg1));
        FF_Nb #(.Nb(32)) ff_tg2(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tg2), .dout(tg2));
        FF_Nb #(.Nb(32)) ff_tg3(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tg3), .dout(tg3));

        assign o_gk0 = tg0 ^ tg2;
        assign o_gk1 = tg1 ^ tg3;

        wire [31:0] i_tp0 = i_gs ^ (i_pk0 & pkj0);
        wire [31:0] i_tp1 = i_gs ^ (i_pk0 & pkj1);
        wire [31:0] i_tp2 =        (i_pk1 & pkj0);
        wire [31:0] i_tp3 =        (i_pk1 & pkj1);

        wire [31:0] tp0,tp1;
        wire [31:0] tp2,tp3;
        FF_Nb #(.Nb(32)) ff_tp0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tp0), .dout(tp0));
        FF_Nb #(.Nb(32)) ff_tp1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tp1), .dout(tp1));
        FF_Nb #(.Nb(32)) ff_tp2(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tp2), .dout(tp2));
        FF_Nb #(.Nb(32)) ff_tp3(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tp3), .dout(tp3));
        assign o_pk0 = tp0 ^ tp2;
        assign o_pk1 = tp1 ^ tp3;
    end else begin                    : masking_non_TI
        wire [31:0] pk0 = i_gs ^ (i_pk0 & pkj1) ^ (i_pk0 | ~pkj0);
        wire [31:0] pk1 = i_gs ^ (i_pk1 & pkj1) ^ (i_pk1 | ~pkj0);  
        FF_Nb #(.Nb(32)) ff_pk0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(pk0), .dout(o_pk0));
        FF_Nb #(.Nb(32)) ff_pk1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(pk1), .dout(o_pk1));

        wire [31:0] gk0 = i_gk0 ^ (gkj0 & i_pk1) ^ (gkj0 | ~i_pk0);
        wire [31:0] gk1 = i_gk1 ^ (gkj1 & i_pk1) ^ (gkj1 | ~i_pk0);
        FF_Nb #(.Nb(32)) ff_gk0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(gk0), .dout(o_gk0));
        FF_Nb #(.Nb(32)) ff_gk1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(gk1), .dout(o_gk1));    
    end
endgenerate
endmodule

module postprocess(
  input wire         sub,
  input wire  [31:0] i_pk0, i_pk1,
  input wire  [31:0] i_gk0, i_gk1,
  output wire [31:0] o_s0 , o_s1
);
assign o_s0 = i_pk0 ^ {i_gk0[30:0],1'b0};
assign o_s1 = i_pk1 ^ {i_gk1[30:0],sub};
endmodule


/* multiplication in GF(2^8)/p[x] = x^8 + x^4 + x^3 + x + 1
  based on circuit minimization: http://cs-www.cs.yale.edu/homes/peralta/CircuitStuff/CMT.html 
  i_a : 8-bit input
  i_b : 8-bit input 
  o_r : 8-bit output = i_a * i_b mod p[x]
*/
module gf256_mul(i_a,i_b,o_r);
input[7:0] i_a;
input[7:0] i_b;
output[7:0] o_r;

wire A0 = i_a[0];
wire A1 = i_a[1];
wire A2 = i_a[2];
wire A3 = i_a[3];
wire A4 = i_a[4];
wire A5 = i_a[5];
wire A6 = i_a[6];
wire A7 = i_a[7];
wire B0 = i_b[0];
wire B1 = i_b[1];
wire B2 = i_b[2];
wire B3 = i_b[3];
wire B4 = i_b[4];
wire B5 = i_b[5];
wire B6 = i_b[6];
wire B7 = i_b[7];
wire T1 = A0 && B0;
wire T2 = A0 && B1;
wire T3 = A1 && B0;
wire T4 = A0 && B2;
wire T5 = A1 && B1;
wire T6 = A2 && B0;
wire T7 = A0 && B3;
wire T8 = A1 && B2;
wire T9 = A2 && B1;
wire T10 = A3 && B0;
wire T11 = A1 && B3;
wire T12 = A2 && B2;
wire T13 = A3 && B1;
wire T14 = A2 && B3;
wire T15 = A3 && B2;
wire T16 = A3 && B3;
wire T17 = A4 && B4;
wire T18 = A4 && B5;
wire T19 = A5 && B4;
wire T20 = A4 && B6;
wire T21 = A5 && B5;
wire T22 = A6 && B4;
wire T23 = A4 && B7;
wire T24 = A5 && B6;
wire T25 = A6 && B5;
wire T26 = A7 && B4;
wire T27 = A5 && B7;
wire T28 = A6 && B6;
wire T29 = A7 && B5;
wire T30 = A6 && B7;
wire T31 = A7 && B6;
wire T32 = A7 && B7;
wire T33 = A0 ^ A4;
wire T34 = A1 ^ A5;
wire T35 = A2 ^ A6;
wire T36 = A3 ^ A7;
wire T37 = B0 ^ B4;
wire T38 = B1 ^ B5;
wire T39 = B2 ^ B6;
wire T40 = B3 ^ B7;
wire T41 = T40 && T36;
wire T42 = T40 && T35;
wire T43 = T40 && T34;
wire T44 = T40 && T33;
wire T45 = T39 && T36;
wire T46 = T39 && T35;
wire T47 = T39 && T34;
wire T48 = T39 && T33;
wire T49 = T38 && T36;
wire T50 = T38 && T35;
wire T51 = T38 && T34;
wire T52 = T38 && T33;
wire T53 = T37 && T36;
wire T54 = T37 && T35;
wire T55 = T37 && T34;
wire T56 = T37 && T33;
wire T57 = T2 ^ T3;
wire T58 = T4 ^ T5;
wire T59 = T6 ^ T32;
wire T60 = T7 ^ T8;
wire T61 = T9 ^ T10;
wire T62 = T60 ^ T61;
wire T63 = T11 ^ T12;
wire T64 = T13 ^ T63;
wire T65 = T14 ^ T15;
wire T66 = T18 ^ T19;
wire T67 = T20 ^ T21;
wire T68 = T22 ^ T67;
wire T69 = T23 ^ T24;
wire T70 = T25 ^ T26;
wire T71 = T69 ^ T70;
wire T72 = T27 ^ T28;
wire T73 = T29 ^ T32;
wire T74 = T30 ^ T31;
wire T75 = T52 ^ T55;
wire T76 = T48 ^ T51;
wire T77 = T54 ^ T76;
wire T78 = T44 ^ T47;
wire T79 = T50 ^ T53;
wire T80 = T78 ^ T79;
wire T81 = T43 ^ T46;
wire T82 = T49 ^ T81;
wire T83 = T42 ^ T45;
wire T84 = T71 ^ T74;
wire T85 = T41 ^ T16;
wire T86 = T85 ^ T68;
wire T87 = T66 ^ T65;
wire T88 = T83 ^ T87;
wire T89 = T58 ^ T59;
wire T90 = T72 ^ T73;
wire T91 = T74 ^ T17;
wire T92 = T64 ^ T91;
wire T93 = T82 ^ T92;
wire T94 = T80 ^ T62;
wire T95 = T94 ^ T90;
wire T96 = T41 ^ T77;
wire T97 = T84 ^ T89;
wire T98 = T96 ^ T97;
wire T99 = T57 ^ T74;
wire T100 = T83 ^ T75;
wire T101 = T86 ^ T90;
wire T102 = T99 ^ T100;
wire T103 = T101 ^ T102;
wire T104 = T1 ^ T56;
wire T105 = T90 ^ T104;
wire T106 = T82 ^ T84;
wire T107 = T88 ^ T105;
wire T108 = T106 ^ T107;
wire T109 = T71 ^ T62;
wire T110 = T86 ^ T109;
wire T111 = T110 ^ T93;
wire T112 = T86 ^ T88;
wire T113 = T89 ^ T112;
wire T114 = T57 ^ T32;
wire T115 = T114 ^ T88;
wire T116 = T115 ^ T93;
wire T117 = T93 ^ T1;

assign o_r[0] = T117;
assign o_r[1] = T116;
assign o_r[2] = T113;
assign o_r[3] = T111;
assign o_r[4] = T108;
assign o_r[5] = T103;
assign o_r[6] = T98;
assign o_r[7] = T95;

endmodule

/* affine transformation in GF(2^8)
  i_a : 8-bit input
  i_b : 8 8-bit rows of 64-bit affine matrix. 
  o_r : 8-bit output
*/
module gf256_aff(i_a,i_m,o_r);
input[ 7:0] i_a;
input[63:0] i_m;
output[7:0] o_r;
/*
wire [7:0] r7 = i_m[63:56];
wire [7:0] r6 = i_m[55:48];
wire [7:0] r5 = i_m[47:40];
wire [7:0] r4 = i_m[39:32];
wire [7:0] r3 = i_m[31:24];
wire [7:0] r2 = i_m[23:16];
wire [7:0] r1 = i_m[15: 8];
wire [7:0] r0 = i_m[ 7: 0];

wire [7:0] m7 = i_a & r7;
wire [7:0] m6 = i_a & r6;
wire [7:0] m5 = i_a & r5;
wire [7:0] m4 = i_a & r4;
wire [7:0] m3 = i_a & r3;
wire [7:0] m2 = i_a & r2;
wire [7:0] m1 = i_a & r1;
wire [7:0] m0 = i_a & r0;

assign o_r[0] = ^m0;
assign o_r[1] = ^m1;
assign o_r[2] = ^m2;
assign o_r[3] = ^m3;
assign o_r[4] = ^m4;
assign o_r[5] = ^m5;
assign o_r[6] = ^m6;
assign o_r[7] = ^m7;
*/

wire [7:0] c7 = i_m[63:56];
wire [7:0] c6 = i_m[55:48];
wire [7:0] c5 = i_m[47:40];
wire [7:0] c4 = i_m[39:32];
wire [7:0] c3 = i_m[31:24];
wire [7:0] c2 = i_m[23:16];
wire [7:0] c1 = i_m[15: 8];
wire [7:0] c0 = i_m[ 7: 0];

wire [7:0] m7 = {8{i_a[7]}} & c7;
wire [7:0] m6 = {8{i_a[6]}} & c6;
wire [7:0] m5 = {8{i_a[5]}} & c5;
wire [7:0] m4 = {8{i_a[4]}} & c4;
wire [7:0] m3 = {8{i_a[3]}} & c3;
wire [7:0] m2 = {8{i_a[2]}} & c2;
wire [7:0] m1 = {8{i_a[1]}} & c1;
wire [7:0] m0 = {8{i_a[0]}} & c0;

assign o_r = m0^m1^m2^m3^m4^m5^m6^m7;

endmodule

module FF_Nb #(parameter Nb=1) (
  input wire  g_resetn, g_clk,
  input wire  ena,
  input wire  [Nb-1:0] din,
  output reg  [Nb-1:0] dout
);

always @(posedge g_clk) begin
  if (!g_resetn)    dout <= {Nb{1'b0}};
  else if (ena)     dout <= din;
end

endmodule
