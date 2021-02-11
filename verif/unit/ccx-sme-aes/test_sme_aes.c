
#include "unit_test.h"

// $SCARV_CPU/src/csp/scarv_cpu_sme.h
#include "scarv_cpu_sme.h"
#include "sme_aes.h"

#define EXPECTED_SMAX  3
#define NREGS         16

uint32_t ck [4] = {
    0x16157e2b, // From FIPS 197 sec A1
    0xa6d2ae28,
    0x8815f7ab,
    0x3c4fcf09
};

// From FIPS 197 sec A1
uint32_t expected_final_rk_word = 0xa60c63b6;

// From FIPS 197 appendix B.
uint32_t pt [4] = {
    0xa8f64332,
    0x8d305a88,
    0xa2983131,
    0x340737e0
};

uint32_t ct [4];

sme_aes128_ctx_t ctx;

int test_main() {

    // Turn off SME for now and get the max number of supported shares.
    sme_off();
    int smax = sme_get_smax();
    
    // Don't bother if we get an unexpected SMAX value.
    if(EXPECTED_SMAX != smax) {test_fail();}

    //
    // Key Expansion
    uint32_t cyc_key_exp_start = scarv_cpu_rdcycle_lo();
    uint32_t ins_key_exp_start = scarv_cpu_rdinstret_lo();
    sme_aes128_enc_key_exp(ctx.rk, ck);
    uint32_t cyc_key_exp_end   = scarv_cpu_rdcycle_lo();
    uint32_t ins_key_exp_end   = scarv_cpu_rdinstret_lo();
    uint32_t cyc_key_exp = cyc_key_exp_end - cyc_key_exp_start;
    uint32_t ins_key_exp = ins_key_exp_end - ins_key_exp_start;

    uint32_t unmasked_rk [44];

    for(int i = 0; i < 44; i ++) {
        uint32_t k = 0;
        for(int s = 0; s < smax; s ++) {
            k ^= ctx.rk[s][i];
        }
        unmasked_rk[i] = k;

        //__puthex32(k); __putchar('\n');
    }

    // Check final word of expanded key. Not a great check but good enough.
    if(unmasked_rk[43] != expected_final_rk_word) {
        test_fail();
    }

    //
    // Block Encrypt.
    uint32_t cyc_block_start = scarv_cpu_rdcycle_lo();
    uint32_t ins_block_start = scarv_cpu_rdinstret_lo();
    sme_aes128_enc_block(ct, pt, ctx.rk);
    uint32_t cyc_block_end   = scarv_cpu_rdcycle_lo();
    uint32_t ins_block_end   = scarv_cpu_rdinstret_lo();
    uint32_t cyc_block = cyc_block_end - cyc_block_start;
    uint32_t ins_block = ins_block_end - ins_block_start;

    // Expected answers from FIPS 197 Appendix B.
    if(ct[0] != 0x1D842539){test_fail();}
    if(ct[1] != 0xFB09DC02){test_fail();}
    if(ct[2] != 0x978511DC){test_fail();}
    if(ct[3] != 0x320B6A19){test_fail();}

    __putstr("Key Expansion cycles/instrs: ");
    __puthex32(cyc_key_exp);__putchar('/');
    __puthex32(ins_key_exp);__putchar('\n');
    __putstr("Block Encrypt cycles/instrs: ");
    __puthex32(cyc_block);__putchar('/');
    __puthex32(ins_block);__putchar('\n');

    return 0;

}
