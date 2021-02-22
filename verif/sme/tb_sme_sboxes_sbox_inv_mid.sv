
module tb_sme_sboxes_sbox_inv_mid (
input g_clk,
input g_resetn,
output reg [17:0] dut_out_y,
output reg [17:0] grm_out_y
);

parameter  SME_SMAX    = 3     ;
localparam RMAX  = SME_SMAX+SME_SMAX*(SME_SMAX-1)/2; // Number of guard shares.
localparam RM    = RMAX-1;
localparam  SM      = SME_SMAX-1;

//
// Input generation
// ------------------------------------------------------------

integer ctr;
initial ctr = 0;

// DUT inputs
reg     [20:0] dut_in_x                     ;
reg     [20:0] dut_in_x_masked [SM:0]       ;
reg            dut_en    =1'b1;             ;
reg     [31:0] dut_rng         [RM:0]       ;

wire    [20:0] dbg = dut_in_x_masked[0]^dut_in_x_masked[1]^dut_in_x_masked[2];

// DUT/GRM outputs.
wire    [17:0] dut_out_y_masked[SM:0]       ;
wire    [17:0] grm_out_w                    ;

// Unmask the dut output
always @(*) begin : unmask_output
    integer i;
    dut_out_y = dut_out_y_masked[0];
    for(i = 1; i < SME_SMAX; i=i+1) begin
        dut_out_y = dut_out_y ^ dut_out_y_masked[i];
    end
end

always @(posedge g_clk) begin
    integer i;
    ctr <= ctr + 1;
    if(ctr % 3==0) begin
        for(i = 0; i < SME_SMAX; i=i+1) begin
            /* verilator lint_off WIDTH */
            dut_in_x   <= $random;
            if(i  > 0) begin
                dut_in_x_masked[i] <= $random;
            end
            /* verilator lint_on  WIDTH */
        end
        for(i = 0; i < RMAX; i=i+1) begin
            dut_rng[i] <= $random;
        end
    end
    grm_out_y <= grm_out_w;
    if(g_resetn && ctr%3==0) begin
        if(dut_out_y != grm_out_y) begin
            $display("ERROR");
            $finish;
        end
    end
end

always @(*) begin
    integer i;
    dut_in_x_masked[0] = dut_in_x;
    for (i = 1; i < SME_SMAX; i=i+1) begin
        dut_in_x_masked[0] = dut_in_x_masked[0] ^ dut_in_x_masked[i];
    end
end

initial begin
    $display("Init");
    $dumpfile("work/waves-sme-sbox-mid.vcd");
    $dumpvars(0, tb_sme_sboxes_sbox_inv_mid);
end

//
// Submodule instances
// ------------------------------------------------------------

//
// Golden reference / un-masked.
riscv_crypto_sbox_inv_mid i_grm(
.x(dut_in_x ),
.y(grm_out_w)
);

//
// DUT / Masked
sme_sbox_inv_mid #(
.SMAX(SME_SMAX)
) i_dut (
.g_clk      (g_clk      ),
.g_resetn   (g_resetn   ),
.en         (dut_en     ),
.rng        (dut_rng    ),
.x          (dut_in_x_masked ),
.y          (dut_out_y_masked)
);

endmodule

