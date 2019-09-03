
//
// module: frv_leak
//
//  Handles the leakage barrier instruction state and some functionality.
//  Contains the configuration register and pseudo random number source.
//
module frv_leak (

input  wire         g_clk           ,
input  wire         g_resetn        ,

input  wire         leak_cfg_load   , // Load a new configuration word.
input  wire [XL:0]  leak_cfg_wdata  , // The new configuration word to load.

output reg  [XL:0]  leak_prng       , // Current PRNG value.
output reg  [12:0]  leak_alcfg      , // Current alcfg register value.

input  wire         leak_fence        // Fence instruction flying past.

);

// Common core parameters and constants
`include "frv_common.vh"

// Is any of this implemented?
parameter XC_CLASS_LEAK       = 1'b1;

// Randomise registers (if set) or zero them (if clear)
parameter XC_CLASS_LEAK_STRONG= 1'b1;

// Reset value for the ALCFG register
parameter ALCFG_RESET_VALUE = 13'b0;

// Reset value for the PRNG.
parameter PRNG_RESET_VALUE  = 32'hABCDEF37;

generate if(XC_CLASS_LEAK) begin // Leakage instructions are implemented
    
    //
    // Process for updating the configuration register.
    always @(posedge g_clk) begin
        if(!g_resetn) begin
            leak_alcfg <= ALCFG_RESET_VALUE;
        end else if(leak_cfg_load) begin
            leak_alcfg <= leak_cfg_wdata[12:0];
        end
    end

    wire n_prng_lsb = leak_prng[31] ~^
                      leak_prng[21] ~^
                      leak_prng[ 1] ~^
                      leak_prng[ 0]  ;
    
    wire [XL:0] n_prng = {leak_prng[XL-1:0], n_prng_lsb};

    //
    // Process for updating the LFSR.
    always @(posedge g_clk) begin
        if(!g_resetn) begin
            leak_prng <= PRNG_RESET_VALUE;
        end else if(leak_fence) begin
            leak_prng <= n_prng;
        end
    end

end else begin // Leakage instructions are not implemented

    always @(*) leak_prng  = {XLEN{1'b0}};

    always @(*) leak_alcfg = 0;

end endgenerate

endmodule