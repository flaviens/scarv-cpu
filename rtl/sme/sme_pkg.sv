
//
// package: sme_pkg
//
//  Package containing common useful functions / types for the SME
//  implementation.
//
package sme_pkg;

// Width of architectural registers
parameter XLEN  = 32      ;
parameter XL    = XLEN - 1;


//
// Wrapper for testing if SME is turned on based on the value of smectl.
function sme_is_on();
    input [XL:0] smectl;
    sme_is_on = |smectl[8:5];
endfunction


//
// Is the supplied register address _potentially_ an SME share?
// If we come up with a complex mapping between share registers and
// addresses later, we only need to change this function.
function sme_is_share_reg();
    input [4:0] addr;
    sme_is_share_reg = addr[4];
endfunction


//
// Holds all information on an instruction going _into_ the SME pipeline.
typedef struct packed {

logic [ 3:0] rs1_addr ;
logic [XL:0] rs1_rdata;

logic [ 3:0] rs2_addr ;
logic [XL:0] rs2_rdata;

logic [ 4:0] shamt    ; // Shift amount for shift/rotate.
logic        op_xor   ;
logic        op_and   ;
logic        op_or    ;
logic        op_notrs2; // invert 0'th share of rs2 for andn/orn/xnor.
logic        op_shift ;
logic        op_rotate;
logic        op_left  ;
logic        op_right ;
logic        op_add   ;
logic        op_sub   ;
logic        op_mask  ; // Enmask 0'th element of rs1 based on smectl_t
logic        op_unmask; // Unmask rs1
logic        op_remask; // remask rs1 based on smectl_t

logic [ 3:0] rd_addr ;

} sme_instr_t;


//
// Holds all information on an instruction result going from SME to the host.
typedef struct packed {

logic [XL:0] rd_wdata;
logic [ 3:0] rd_addr ;

} sme_result_t;

endpackage

