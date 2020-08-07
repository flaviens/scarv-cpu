
#include <assert.h>

#include "dut_wrapper.hpp"

/*!
*/
dut_wrapper::dut_wrapper (
    memory_bus    * mem         ,
    bool            dump_waves  ,
    std::string     wavefile
){


    this -> dut                    = new Vscarv_ccx_top_v();

    this -> dump_waves             = dump_waves;
    this -> vcd_wavefile_path      = wavefile;
    this -> mem                    = mem;

    this -> mem_agent               = new sram_agent(mem);
    this -> mem_agent -> mem_req   = &this -> dut -> if_ext_req  ;
    this -> mem_agent -> mem_gnt   = &this -> dut -> if_ext_gnt  ;
    this -> mem_agent -> mem_wen   = &this -> dut -> if_ext_wen  ;
    this -> mem_agent -> mem_error = &this -> dut -> if_ext_error;
    this -> mem_agent -> mem_strb  = &this -> dut -> if_ext_strb ;
    this -> mem_agent -> mem_addr  = &this -> dut -> if_ext_addr ;
    this -> mem_agent -> mem_rdata = &this -> dut -> if_ext_rdata;
    this -> mem_agent -> mem_wdata = &this -> dut -> if_ext_wdata;

    Verilated::traceEverOn(this -> dump_waves);

    if(this -> dump_waves){
        this -> trace_fh = new VerilatedVcdC;
        this -> dut -> trace(this -> trace_fh, 99);
        this -> trace_fh -> open(this ->vcd_wavefile_path.c_str());
    }

    this -> sim_time               = 0;

}
    
//! Put the dut in reset.
void dut_wrapper::dut_set_reset() {

    // Put model in reset.
    this -> dut -> g_resetn     = 0;
    this -> dut -> f_clk        = 0;

    this -> mem_agent -> set_reset();

}
    
//! Take the DUT out of reset.
void dut_wrapper::dut_clear_reset() {
    
    this -> dut -> g_resetn = 1;
    
    this -> mem_agent -> clear_reset();

}


//! Simulate the DUT for a single clock cycle
void dut_wrapper::dut_step_clk() {

    vluint8_t prev_clk;

    for(uint32_t i = 0; i < this -> evals_per_clock; i++) {

        prev_clk = this -> dut -> f_clk;
        
        if(i == this -> evals_per_clock / 2) {
            
            this -> dut -> f_clk = !this -> dut -> f_clk;
            
            if(this -> dut -> f_clk == 1){

                this -> posedge_gclk();
            }
       
        } 
        
        this -> dut      -> eval();
        
        // Drive interface agents
        this -> mem_agent -> drive_signals();

        this -> dut -> eval();

        this -> sim_time ++;

        if(this -> dump_waves) {
            this -> trace_fh -> dump(this -> sim_time);
        }

    }

}


void dut_wrapper::posedge_gclk () {

    this -> mem_agent -> posedge_clk();

    // Do we need to capture a trace item?
    if(this -> dut -> cpu_trs_valid) {
        this -> dut_trace.push (
            {
                this -> dut -> cpu_trs_pc,
                this -> dut -> cpu_trs_instr
            }
        );
    }
}


bool dut_wrapper::rand_chance(int x, int y) {
    return (rand() % y) < x;
}


bool dut_wrapper::rand_set_uint8(int x, int y, vluint8_t * d) {
    if(rand_chance(x,y)) {
        *d = 1;
        return true;
    } else {
        *d = 0;
        return false;
    }
}

