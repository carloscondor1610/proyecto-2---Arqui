`timescale 1ns / 1ps
module forwarding_unit (
    input wire [4:0] Rs1E, Rs2E, Rs1E1, Rs2E1,
    input wire UsesRs1E0, UsesRs2E0, UsesRs1E1, UsesRs2E1,
    input wire [4:0] RdM, RdM1, RdW, RdW1,
    input wire RegWriteM, RegWriteM1, RegWriteW, RegWriteW1,
    input wire ValidM0, ValidM1, ValidW0, ValidW1,
    input wire [1:0] ResultSrcM, ResultSrcM1,
    output wire [2:0] ForwardAE, ForwardBE, ForwardAE1, ForwardBE1,
    output wire ForwardStall0, ForwardStall1
);
    // 0=no bypass, 1=MEM0, 2=MEM1, 3=WB0, 4=WB1.
    // Youngest available matching producer wins: MEM1, MEM0, WB1, WB0.
    function [3:0] choose;
        input [4:0] rs;
        input use_source;
        input [4:0] m0, m1, w0, w1;
        input wm0, wm1, ww0, ww1;
        input vm0, vm1, vw0, vw1;
        input [1:0] result0, result1;
        begin
            choose=4'b0000;
            if(use_source && rs != 5'd0) begin
                if(vm1 && wm1 && m1 == rs) begin
                    if(result1 == 2'b01) choose=4'b1000;
                    else choose=4'b0010;
                end else if(vm0 && wm0 && m0 == rs) begin
                    if(result0 == 2'b01) choose=4'b1000;
                    else choose=4'b0001;
                end else if(vw1 && ww1 && w1 == rs) choose=4'b0100;
                else if(vw0 && ww0 && w0 == rs) choose=4'b0011;
            end
        end
    endfunction
    wire [3:0] a0=choose(Rs1E,UsesRs1E0,RdM,RdM1,RdW,RdW1,
        RegWriteM,RegWriteM1,RegWriteW,RegWriteW1,ValidM0,ValidM1,ValidW0,ValidW1,ResultSrcM,ResultSrcM1);
    wire [3:0] b0=choose(Rs2E,UsesRs2E0,RdM,RdM1,RdW,RdW1,
        RegWriteM,RegWriteM1,RegWriteW,RegWriteW1,ValidM0,ValidM1,ValidW0,ValidW1,ResultSrcM,ResultSrcM1);
    wire [3:0] a1=choose(Rs1E1,UsesRs1E1,RdM,RdM1,RdW,RdW1,
        RegWriteM,RegWriteM1,RegWriteW,RegWriteW1,ValidM0,ValidM1,ValidW0,ValidW1,ResultSrcM,ResultSrcM1);
    wire [3:0] b1=choose(Rs2E1,UsesRs2E1,RdM,RdM1,RdW,RdW1,
        RegWriteM,RegWriteM1,RegWriteW,RegWriteW1,ValidM0,ValidM1,ValidW0,ValidW1,ResultSrcM,ResultSrcM1);
    assign ForwardAE=a0[2:0];
    assign ForwardBE=b0[2:0];
    assign ForwardAE1=a1[2:0];
    assign ForwardBE1=b1[2:0];
    assign ForwardStall0=a0[3] || b0[3];
    assign ForwardStall1=a1[3] || b1[3];
endmodule
