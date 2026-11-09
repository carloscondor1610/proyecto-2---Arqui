`timescale 1ns / 1ps

module regfile_dual (
    input wire clk,

    // Escritura de la via 0
    input wire we0,
    input wire [4:0] wa0,
    input wire [31:0] wd0,

    // Escritura de la via 1
    input wire we1,
    input wire [4:0] wa1,
    input wire [31:0] wd1,

    // Lecturas de la via 0
    input wire [4:0] a1_0,
    input wire [4:0] a2_0,

    // Lecturas de la via 1
    input wire [4:0] a1_1,
    input wire [4:0] a2_1,

    // Cuatro puertos de lectura
    output wire [31:0] rd1_0,
    output wire [31:0] rd2_0,
    output wire [31:0] rd1_1,
    output wire [31:0] rd2_1
);

    reg [31:0] rf [0:31];

    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            rf[i] = 32'd0;
    end

    // Escritura simultanea de dos registros
    always @(posedge clk) begin
        if (we0 && wa0 != 5'd0)
            rf[wa0] <= wd0;

        if (we1 && wa1 != 5'd0)
            rf[wa1] <= wd1;
    end

    // Lectura con bypass de Writeback
    function [31:0] read_rf;
        input [4:0] addr;
        begin
            if (addr == 5'd0)
                read_rf = 32'd0;
            else if (we1 && wa1 == addr)
                read_rf = wd1;
            else if (we0 && wa0 == addr)
                read_rf = wd0;
            else
                read_rf = rf[addr];
        end
    endfunction

    assign rd1_0 = read_rf(a1_0);
    assign rd2_0 = read_rf(a2_0);

    assign rd1_1 = read_rf(a1_1);
    assign rd2_1 = read_rf(a2_1);

endmodule
