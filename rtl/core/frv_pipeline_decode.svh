wire dec_lui        = d_data[6:2] == 5'h0D && d_data[1:0] == 2'd3;
wire dec_auipc      = d_data[6:2] == 5'h05 && d_data[1:0] == 2'd3;
wire dec_jal        = d_data[6:2] == 5'h1b && d_data[1:0] == 2'd3;
wire dec_jalr       = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h19 && d_data[1:0] == 2'd3;
wire dec_beq        = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_bne        = d_data[14:12] == 3'd1 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_blt        = d_data[14:12] == 3'd4 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_bge        = d_data[14:12] == 3'd5 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_bltu       = d_data[14:12] == 3'd6 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_bgeu       = d_data[14:12] == 3'd7 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_lb         = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h00 && d_data[1:0] == 2'd3;
wire dec_lh         = d_data[14:12] == 3'd1 && d_data[6:2] == 5'h00 && d_data[1:0] == 2'd3;
wire dec_lw         = d_data[14:12] == 3'd2 && d_data[6:2] == 5'h00 && d_data[1:0] == 2'd3;
wire dec_lbu        = d_data[14:12] == 3'd4 && d_data[6:2] == 5'h00 && d_data[1:0] == 2'd3;
wire dec_lhu        = d_data[14:12] == 3'd5 && d_data[6:2] == 5'h00 && d_data[1:0] == 2'd3;
wire dec_sb         = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h08 && d_data[1:0] == 2'd3;
wire dec_sh         = d_data[14:12] == 3'd1 && d_data[6:2] == 5'h08 && d_data[1:0] == 2'd3;
wire dec_sw         = d_data[14:12] == 3'd2 && d_data[6:2] == 5'h08 && d_data[1:0] == 2'd3;
wire dec_addi       = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_slti       = d_data[14:12] == 3'd2 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_sltiu      = d_data[14:12] == 3'd3 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_xori       = d_data[14:12] == 3'd4 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_ori        = d_data[14:12] == 3'd6 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_andi       = d_data[14:12] == 3'd7 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_slli       = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd1 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_srli       = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd5 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_srai       = d_data[31:25] == 7'd32 && d_data[14:12] == 3'd5 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_add        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_sub        = d_data[31:25] == 7'd32 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_sll        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd1 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_slt        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd2 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_sltu       = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd3 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_xor        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd4 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_srl        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd5 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_sra        = d_data[31:25] == 7'd32 && d_data[14:12] == 3'd5 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_or         = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd6 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_and        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd7 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_fence      = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h03 && d_data[1:0] == 2'd3;
wire dec_fence_i    = d_data[14:12] == 3'd1 && d_data[6:2] == 5'h03 && d_data[1:0] == 2'd3;
wire dec_mul        = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_mulh       = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd1 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_mulhsu     = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd2 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_mulhu      = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd3 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_div        = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd4 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_divu       = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd5 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_rem        = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd6 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_remu       = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd7 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_ecall      = d_data[11:7] == 5'd0 && d_data[19:15] == 5'd0 && d_data[31:20] == 12'h000 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_ebreak     = d_data[11:7] == 5'd0 && d_data[19:15] == 5'd0 && d_data[31:20] == 12'h001 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_mret       = d_data[11:7] == 5'd0 && d_data[19:15] == 5'd0 && d_data[31:20] == 12'h302 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_wfi        = d_data[11:7] == 5'd0 && d_data[19:15] == 5'd0 && d_data[31:20] == 12'h105 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrw      = d_data[14:12] == 3'd1 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrs      = d_data[14:12] == 3'd2 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrc      = d_data[14:12] == 3'd3 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrwi     = d_data[14:12] == 3'd5 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrsi     = d_data[14:12] == 3'd6 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrci     = d_data[14:12] == 3'd7 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_c_addi4spn = d_data[1:0] == 2'd0 && d_data[15:13] == 3'd0 && d_data[12:5] != 0;
wire dec_c_lw       = d_data[1:0] == 2'd0 && d_data[15:13] == 3'd2;
wire dec_c_sw       = d_data[1:0] == 2'd0 && d_data[15:13] == 3'd6;
wire dec_c_nop      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd0 && d_data[12:12] == 1'd0 && d_data[11:7] == 5'd0 && d_data[6:2] == 5'd0;
wire dec_c_addi     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd0;
wire dec_c_jal      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd1;
wire dec_c_li       = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd2;
wire dec_c_addi16sp = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd3 && d_data[11:7] == 5'd2;
wire dec_c_lui      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd3 && d_data[11:7] != 5'd2 && {d_data[12],d_data[6:2]} != 0;
wire dec_c_srli     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[11:10] == 2'd0 && d_data[12] == 1'b0;
wire dec_c_srai     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[11:10] == 2'd1 && d_data[12] == 1'b0;
wire dec_c_andi     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[11:10] == 2'd2;
wire dec_c_sub      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[11:10] == 2'd3 && d_data[6:5] == 2'd0;
wire dec_c_xor      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[11:10] == 2'd3 && d_data[6:5] == 2'd1;
wire dec_c_or       = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[11:10] == 2'd3 && d_data[6:5] == 2'd2;
wire dec_c_and      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[11:10] == 2'd3 && d_data[6:5] == 2'd3;
wire dec_c_j        = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd5;
wire dec_c_beqz     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd6;
wire dec_c_bnez     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd7;
wire dec_c_slli     = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd0 && d_data[12] == 0;
wire dec_c_lwsp     = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd2 && d_data[11:7] != 0;
wire dec_c_jr       = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[6:2] == 5'd0 && d_data[11:7] != 0;
wire dec_c_mv       = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[6:2] != 0;
wire dec_c_ebreak   = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd1 && d_data[11:7] == 5'd0 && d_data[6:2] == 5'd0;
wire dec_c_jalr     = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd1 && d_data[6:2] == 5'd0 && d_data[11:7] != 0;
wire dec_c_add      = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd1 && d_data[6:2] != 5'd0;
wire dec_c_swsp     = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd6;

// TODO: Correct decode of crypto extension instructions.
wire dec_ssm4_ed        = (d_data & 32'h3e00707f) == 32'h800302b;
wire dec_ssm4_ks        = (d_data & 32'h3e00707f) == 32'ha00302b;
wire dec_saes32_encsm   = (d_data & 32'h3e00707f) == 32'h202b;
wire dec_saes32_encs    = (d_data & 32'h3e00707f) == 32'h200202b;
wire dec_saes32_decsm   = (d_data & 32'h3e00707f) == 32'h400202b;
wire dec_saes32_decs    = (d_data & 32'h3e00707f) == 32'h600202b;
wire dec_saes64_ks1     = (d_data & 32'hff00707f) == 32'h800202b;
wire dec_saes64_ks2     = (d_data & 32'hfe00707f) == 32'ha00202b;
wire dec_saes64_imix    = (d_data & 32'hfff0707f) == 32'hc10202b;
wire dec_saes64_encsm   = (d_data & 32'hfe00707f) == 32'he00202b;
wire dec_saes64_encs    = (d_data & 32'hfe00707f) == 32'h1000202b;
wire dec_saes64_decsm   = (d_data & 32'hfe00707f) == 32'h1200202b;
wire dec_saes64_decs    = (d_data & 32'hfe00707f) == 32'h1400202b;
wire dec_ssha256_sig0   = (d_data & 32'hfff0707f) == 32'he00702b;
wire dec_ssha256_sig1   = (d_data & 32'hfff0707f) == 32'he10702b;
wire dec_ssha256_sum0   = (d_data & 32'hfff0707f) == 32'he20702b;
wire dec_ssha256_sum1   = (d_data & 32'hfff0707f) == 32'he30702b;
wire dec_ssm3_p0        = (d_data & 32'hfff0707f) == 32'he80702b;
wire dec_ssm3_p1        = (d_data & 32'hfff0707f) == 32'he90702b;
wire dec_ssha512_sig0l  = (d_data & 32'hfe00707f) == 32'h1000702b;
wire dec_ssha512_sig0h  = (d_data & 32'hfe00707f) == 32'h1200702b;
wire dec_ssha512_sig1l  = (d_data & 32'hfe00707f) == 32'h1400702b;
wire dec_ssha512_sig1h  = (d_data & 32'hfe00707f) == 32'h1600702b;
wire dec_ssha512_sum0r  = (d_data & 32'hfe00707f) == 32'h1800702b;
wire dec_ssha512_sum1r  = (d_data & 32'hfe00707f) == 32'h1a00702b;
wire dec_ssha512_sig0   = (d_data & 32'hfff0707f) == 32'he40702b;
wire dec_ssha512_sig1   = (d_data & 32'hfff0707f) == 32'he50702b;
wire dec_ssha512_sum0   = (d_data & 32'hfff0707f) == 32'he60702b;
wire dec_ssha512_sum1   = (d_data & 32'hfff0707f) == 32'he70702b;
wire dec_pollentropy    = (d_data & 32'hfe0ff07f) == 32'he05702b;



wire invalid_instr = !(dec_lui       ||dec_auipc     ||dec_jal
||dec_jalr      ||dec_beq       ||dec_bne       ||dec_blt       ||dec_bge
||dec_bltu      ||dec_bgeu      ||dec_lb        ||dec_lh        ||dec_lw
||dec_lbu       ||dec_lhu       ||dec_sb        ||dec_sh        ||dec_sw
||dec_addi      ||dec_slti      ||dec_sltiu     ||dec_xori      ||dec_ori
||dec_andi      ||dec_slli      ||dec_srli      ||dec_srai      ||dec_add
||dec_sub       ||dec_sll       ||dec_slt       ||dec_sltu      ||dec_xor
||dec_srl       ||dec_sra       ||dec_or        ||dec_and       ||dec_fence
||dec_fence_i   ||dec_mul       ||dec_mulh      ||dec_mulhsu    ||dec_mulhu
||dec_div       ||dec_divu      ||dec_rem       ||dec_remu      
||dec_ecall     ||dec_ebreak    ||dec_mret      ||dec_wfi
||dec_csrrw     ||dec_csrrs     ||dec_csrrc     ||dec_csrrwi    ||dec_csrrsi
||dec_csrrci    ||dec_c_addi4spn||dec_c_lw      ||dec_c_sw      ||dec_c_nop
||dec_c_addi    ||dec_c_jal     ||dec_c_li      ||dec_c_addi16sp||dec_c_lui
||dec_c_srli    ||dec_c_srai    ||dec_c_andi    ||dec_c_sub     ||dec_c_xor
||dec_c_or      ||dec_c_and     ||dec_c_j       ||dec_c_beqz    ||dec_c_bnez
||dec_c_slli    ||dec_c_lwsp    ||dec_c_jr      ||dec_c_mv
||dec_c_ebreak  ||dec_c_jalr    ||dec_c_add     ||dec_c_swsp    ||
dec_saes32_encs     ||
dec_saes32_encsm    || dec_saes32_decs     || dec_saes32_decsm    ||
dec_ssha256_sig0    || dec_ssha256_sig1    || dec_ssha256_sum0    ||
dec_ssha256_sum1    || dec_ssha512_sum0r   || dec_ssha512_sum1r   ||
dec_ssha512_sig0l   || dec_ssha512_sig0h   || dec_ssha512_sig1l   ||
dec_ssha512_sig1h   || dec_ssm3_p0         || dec_ssm3_p1         ||
dec_ssm4_ks         || dec_ssm4_ed
);
