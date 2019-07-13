#include <assert.h>

#include <map>
#include <queue>
#include <string>
#include <iostream>
#include <cstdlib>
#include <cstdio>

#include "srec.hpp"
#include "memory_device.hpp"
#include "sram_agent.hpp"
#include "dut_wrapper.hpp"

uint32_t    TB_PASS_ADDRESS     = 0;
uint32_t    TB_FAIL_ADDRESS     = -1;

bool        quiet               = false;

bool        dump_waves          = false;
std::string vcd_wavefile_path   = "waves.vcd";

bool        dump_signature      = false;
std::string sig_dump_path      = "signature.sig";
uint32_t    SIG_START           = 0; //!< Base address of test signature.
uint32_t    SIG_END             = 0; //!< End address of test signature.
uint32_t    REG_ADDR            = 0; //!< Base address of register state.

bool        verif_signature     = false;
std::string sig_verif_path      = "";

uint64_t    max_sim_time        = 10000;

bool        load_srec           = false;
std::string srec_path           = "";

/*
@brief Responsible for parsing all of the command line arguments.
*/
void process_arguments(int argc, char ** argv) {

    for(int i =0; i < argc; i ++) {
        std::string s (argv[i]);

        if(s.find("+IMEM=") != std::string::npos) {
            // Extract the file path.
            srec_path = s.substr(6);
            load_srec = true;
        }
        else if(s.find("+WAVES=") != std::string::npos) {
            std::string fpath = s.substr(7);
            vcd_wavefile_path = fpath;
            if(vcd_wavefile_path != "") {
                dump_waves        = true;
                if(!quiet){
                std::cout << ">> Dumping waves to: " << vcd_wavefile_path 
                          << std::endl;
                }
            }
        }
        else if(s.find("+TIMEOUT=") != std::string::npos) {
            std::string time = s.substr(9);
            max_sim_time= std::stoul(time) * 10;
            if(!quiet) {
            std::cout << ">> Timeout after " << time <<" cycles."<<std::endl;
            }
        }
        else if(s.find("+PASS_ADDR=") != std::string::npos) {
            std::string addr = s.substr(11);
            TB_PASS_ADDRESS = std::stoul(addr,NULL,0) & 0xFFFFFFFF;
            if(!quiet){
            std::cout << ">> Pass Address: 0x" << std::hex << TB_PASS_ADDRESS
                      << std::endl;
            }
        }
        else if(s.find("+FAIL_ADDR=") != std::string::npos) {
            std::string addr = s.substr(11);
            TB_FAIL_ADDRESS = std::stoul(addr,NULL,0) & 0xFFFFFFFF;
            if(!quiet){
            std::cout << ">> Fail Address: 0x" << std::hex << TB_FAIL_ADDRESS
                      << std::endl;
            }
        }
        else if(s.find("+SIG_START=") != std::string::npos) {
            std::string addr = s.substr(11);
            SIG_START= std::stoul(addr,NULL,0) & 0xFFFFFFFF;
            if(!quiet){
            std::cout << ">> Signature Start: 0x" << std::hex << SIG_START
                      << std::endl;
            }
        }
        else if(s.find("+SIG_END=") != std::string::npos) {
            std::string addr = s.substr(9);
            SIG_END = std::stoul(addr,NULL,0) & 0xFFFFFFFF;
            if(!quiet){
            std::cout << ">> Signature End: 0x" << std::hex << SIG_END
                      << std::endl;
            }
        }
        else if(s.find("+REG_ADDR=") != std::string::npos) {
            std::string addr = s.substr(10);
            REG_ADDR = std::stoul(addr,NULL,0) & 0xFFFFFFFF;
            if(!quiet){
            std::cout << ">> Regstate Address: 0x" << std::hex << REG_ADDR
                      << std::endl;
            }
        }
        else if(s.find("+SIG_PATH=") != std::string::npos) {
            std::string fpath = s.substr(10);
            sig_dump_path = fpath;
            if(sig_dump_path != "") {
                dump_signature = true;
                if(!quiet){
                std::cout << ">> Dumping signature to: " << sig_dump_path 
                          << std::endl;
                }
            }
        }
        else if(s.find("+SIG_VERIF=") != std::string::npos) {
            std::string fpath = s.substr(11);
            sig_verif_path = fpath;
            if(sig_verif_path != "") {
                verif_signature = true;
                if(!quiet){
                std::cout << ">> Verify against signature: " << sig_verif_path
                          << std::endl;
                }
            }
        }
        else if(s == "+q") {
            quiet = true;
        }
        else if(s == "--help" || s == "-h") {
            std::cout << argv[0] << " [arguments]" << std::endl
            << "\t+q                            -" << std::endl
            << "\t+IMEM=<srec input file path>  -" << std::endl
            << "\t+WAVES=<VCD dump file path>   -" << std::endl
            << "\t+TIMEOUT=<timeout after N>    -" << std::endl
            << "\t+PASS_ADDR=<hex number>       -" << std::endl
            << "\t+FAIL_ADDR=<hex number>       -" << std::endl
            << "\t+SIG_START=<hex number>       -" << std::endl
            << "\t+SIG_END=<hex number>       -" << std::endl
            << "\t+REG_ADDR=<hex number>       -" << std::endl
            << "\t+SIG_PATH=<filepath>         -" << std::endl
            ;
            exit(0);
        }
    }
}


void load_srec_file (
    memory_device * mem
) {
    std::cout <<">> Loading srec: " << srec_path << std::endl;

    srec::srec_file fh(srec_path);

    for(auto it  = fh.data.begin();
             it != fh.data.end();
             it ++) {
        mem -> write_byte(it -> first, it -> second);
    }
}

//! Write out the memory signature for verification
void dump_signature_file (
    memory_device *mem
) {

    FILE * fh = fopen(sig_dump_path.c_str(),"w");

    for(uint32_t i = SIG_START; i < SIG_END; i+=4) {
        
        fprintf(fh,"%02x", mem -> read_byte(i+3));
        fprintf(fh,"%02x", mem -> read_byte(i+2));
        fprintf(fh,"%02x", mem -> read_byte(i+1));
        fprintf(fh,"%02x", mem -> read_byte(i+0));
        fprintf(fh,"\n");

    }

    fclose(fh);

}

int a2h(char c)
{
    int num = (int) c;
    if(num < 58 && num > 47){
        return num - 48;
    }
    if(num < 103 && num > 96){
        return num - 87;
    }
    return num;
}

//! Verify the in-memory signature against the supplied file
bool verif_signature_file (
    memory_device *mem
) {
    std::cout << ">> Checking signature..." << std::endl;

    FILE * fh = fopen(sig_verif_path.c_str(),"r");

    bool result = true;

    std::cout<<">> Address  Reference    Dut"<<std::endl;

    for(uint32_t i = SIG_START; i < SIG_END; i+=4) {
        
        uint8_t dut[4];
        dut[3] = mem -> read_byte(i+3);
        dut[2] = mem -> read_byte(i+2);
        dut[1] = mem -> read_byte(i+1);
        dut[0] = mem -> read_byte(i+0);
        
        uint8_t sig[4];
        sig[3] = (a2h(getc(fh)) << 4) | a2h(getc(fh)) ;
        sig[2] = (a2h(getc(fh)) << 4) | a2h(getc(fh)) ;
        sig[1] = (a2h(getc(fh)) << 4) | a2h(getc(fh)) ;
        sig[0] = (a2h(getc(fh)) << 4) | a2h(getc(fh)) ;
                 getc(fh); // Read to newline
        
        printf(">> %08X ", i);
        printf("%02X %02X %02X %02X, ", sig[3],sig[2],sig[1],sig[0]);
        printf("%02X %02X %02X %02X\n", dut[3],dut[2],dut[1],dut[0]);
        fflush(stdout);

        for(int j = 0; j < 4; j++) {
            if(dut[j] != sig[j]) {
                std::cout << ">> Signature mismatch" <<std::endl;
                result = false;
            }
        }

    }

    fclose(fh);

    if(result) {
        std::cout << ">> Signature check passed." << std::endl;
    }

    return result;
}

/*
@brief Top level simulation function.
*/
int main(int argc, char** argv) {

    process_arguments(argc, argv);

    memory_device imem (0x80000000, 8192*2);

    if(load_srec) {
        load_srec_file(&imem);
    }

    dut_wrapper           dut (
        &imem,
        dump_waves,
        vcd_wavefile_path
    );

    // Start in reset
    dut.dut_set_reset();
    
    // Run the DUT for a few cycles while held in reset.
    for(int i = 0; i < 5; i ++) {
        dut.dut_step_clk();
    }
    
    // Start running the DUT proper.
    dut.dut_clear_reset();

    bool finish_sim = false;
    bool test_passed= true;
    dut_trace_pkt_t trs_item;

    while(dut.get_sim_time() < max_sim_time && !finish_sim) {
        
        dut.dut_step_clk();

        if(dut.dut_trace.empty() == false) {
            trs_item = dut.dut_trace.front();
            
            if(trs_item.program_counter == TB_PASS_ADDRESS) {
                test_passed = true;
                finish_sim  = true;
            } else if (trs_item.program_counter == TB_FAIL_ADDRESS) {
                test_passed = false;
                finish_sim  = true;
            }

            dut.dut_trace.pop();
        }

    }

    if(dut.dump_waves) {
        dut.trace_fh -> close();
    }

    if(dump_signature) {
        dump_signature_file(&imem);
    }

    bool verif_result = true;

    if(verif_signature) {
        verif_result = verif_signature_file(&imem);
        test_passed &= verif_result;
    }

    if(dut.get_sim_time() >= max_sim_time) {
        
        std::cout << ">> TIMEOUT" << std::endl;
        return 1;

    } else if(test_passed) {
        
        std::cout << ">> SIM PASS" << std::endl;
        return 0;

    } else if(!verif_result) {
        
        std::cout << ">> SIG FAIL" << std::endl;
        return 3;
        
    } else {

        std::cout << ">> SIM FAIL" << std::endl;
        return 2;

    }

}