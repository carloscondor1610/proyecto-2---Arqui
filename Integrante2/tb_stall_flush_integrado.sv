`timescale 1ns/1ps
module tb_stall_flush_integrado;
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0,tb_stall_flush_integrado);
    end
    reg clk=0;
    reg reset=1;
    reg [1:0] advance=2;
    reg redirect=0;
    reg [31:0] redirect_pc=0;
    reg stallD=0,flushD=0;
    reg we_test=0;
    reg [4:0] wa_test=0;
    reg [31:0] wd_test=0;
    wire [31:0] pcF,pc1F,instr0D,instr1D,result0,result1;
    wire valid0D,valid1D;
    integer pass=0, fail=0;
    reg [31:0] pc_antes,instr_antes;
    always #5 clk=~clk;
    datapath_dual dut (
        .clk(clk),.reset(reset),.advance(advance),
        .redirect(redirect),.redirect_pc(redirect_pc),.stallD(stallD),.flushD(flushD),
        .we_test(we_test),.wa_test(wa_test),.wd_test(wd_test),
        .pcF(pcF),.pc1F(pc1F),.instr0D(instr0D),.instr1D(instr1D),
        .valid0D(valid0D),.valid1D(valid1D),.result0(result0),.result1(result1)
    );
    task check;
        input condition;
        input [255:0] description;
        begin
            if(condition) begin pass=pass+1;$display("PASS: %0s",description); end
            else begin fail=fail+1;$display("FAIL: %0s",description); end
        end
    endtask
    initial begin
        $display("===== STALL / FLUSH INTEGRADO =====");
        repeat(2) @(negedge clk);
        reset=0;
        repeat(3) @(negedge clk);
        pc_antes=pcF;
        force dut.StallF_H=1'b1;
        @(posedge clk); #1;
        check(pcF===pc_antes,"StallF mantiene PC");
        @(negedge clk);
        release dut.StallF_H;
        instr_antes=instr0D;
        force dut.StallD_H=1'b1;
        @(posedge clk); #1;
        check(instr0D===instr_antes,"StallD mantiene instruccion");
        @(negedge clk);
        release dut.StallD_H;
        force dut.FlushD_H=1'b1;
        @(posedge clk); #1;
        check(valid0D===1'b0 && valid1D===1'b0,"FlushD invalida ambas vias");
        @(negedge clk);
        release dut.FlushD_H;
        force dut.FlushE_H=1'b1;
        @(posedge clk); #1;
        check(dut.valid0E===1'b0 && dut.valid1E===1'b0,"FlushE invalida ambas vias");
        @(negedge clk);
        release dut.FlushE_H;
        $display("==============================");
        $display("RESULTADO: %0d PASS / %0d FAIL",pass,fail);
        $display("==============================");
        if(fail!=0) $fatal(1,"TEST STALL/FLUSH FAILED");
        $display("TEST STALL/FLUSH PASSED");
        $finish;
    end
endmodule
