`ifndef __DECODE_SV
`define __DECODE_SV

module decode
    import common::*;
    import pipes::*;(
        input logic clk,
        input u32 rd1, rd2,
        input f_d_reg_t f_d_reg,
        input logic stallD, flushD,
        output d_e_reg_t d_e_reg
    );

    //register
    f_d_reg_t f_d;
    always_ff @(posedge clk) begin
        if(flushD) f_d <= '0;
        else if(!stallD) f_d <= f_d_reg;
    end

    u6 op, func;
    logic ext_op;

    assign op = f_d.instruction[31:26];
    assign func = f_d.instruction[5:0];

    assign d_e_reg.pc_plus_4 = f_d.pc_plus_4;
    assign d_e_reg.rd1 = rd1;
    assign d_e_reg.rd2 = rd2;
    
    assign d_e_reg.rs = f_d.instruction[25:21];
    assign d_e_reg.rt = f_d.instruction[20:16];
    assign d_e_reg.rd = f_d.instruction[15:11];
    assign d_e_reg.offset = f_d.instruction[25:0];

    assign ext_op = (op == F6_ADDI || op == F6_LW || op == F6_SW || op == F6_BEQ);

    assign d_e_reg.reg_write = (op == F6_R_TYPE || op == F6_ADDI || op == F6_LW) && (f_d.instruction != 32'b0);
    assign d_e_reg.mem_to_reg = (op == F6_LW);
    assign d_e_reg.mem_write = (op == F6_SW);
    assign d_e_reg.alu_src = (op == F6_ADDI || op == F6_LW || op == F6_SW);
    assign d_e_reg.reg_dst = (op == F6_R_TYPE);
    assign d_e_reg.branch = (op == F6_BEQ);
    assign d_e_reg.jump = (op == F6_J);
    assign d_e_reg.alu_op = (op == F6_R_TYPE) ? func : op;

    imm_extend zero_extend(.extop(ext_op), .imm16(f_d.instruction[15:0]), .imm32(d_e_reg.imm32));
endmodule

module imm_extend
    import common::*;
    import pipes::*;(
        input logic extop,
        input u16 imm16,
        output u32 imm32
    );
    
    always_comb begin
        if(extop == 1'b0) imm32 = {16'b0, imm16[15:0]};
        else imm32 = {{16{imm16[15]}}, imm16[15:0]};
    end

endmodule

`endif
