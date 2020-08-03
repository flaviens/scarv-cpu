
#include "scarv_cpu_csp.h"
#include "unit_test.h"

volatile uint8_t        trap_seen    = 0;
volatile char           loaded_value    ;
test_trap_handler_cfg   trap_cfg        ;

int test_main() {
    
    trap_cfg.expect_trap    = 1     ;
    trap_cfg.check_mcause   = 1     ;
    trap_cfg.expect_mcause  = 0x1 << SCARV_CPU_MCAUSE_LDACCESS;
    trap_cfg.step_over_mepc = 1     ;
    trap_cfg.check_mtval    = 1     ;
    trap_cfg.trap_seen      = &trap_seen;

    // Try to load from some un-mapped addresses.
    uint32_t addr0  = 0xFFFFFFFF;
    trap_cfg.expect_mtval = addr0;
    setup_test_trap_handler(&trap_cfg);
    trap_seen       = 0;
    char * ptr_0    = (char*)(addr0);
    loaded_value    = ptr_0[0];

    if(!trap_seen) {
        __putstr("Trap not seen.\n"); test_fail();
    }
    
    // Try to load a mapped addresses.
    trap_cfg.expect_trap = 0;
    setup_test_trap_handler(&trap_cfg);
    trap_seen       = 0;
    char * ptr_1    = (char*)&test_main;
    loaded_value    = ptr_1[0];

    if(trap_seen) {
        __putstr("Trap seen.\n"); test_fail();
    }

    return 0;

}
