`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2026 11:09:37 AM
// Design Name: 
// Module Name: exmem_dual
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module exmem_dual #(
    parameter WIDTH = 105
)(
    input wire clk,
    input wire reset,
    input wire enable,

    // Flushing independiente para cada via
    input wire flush0,
    input wire flush1,

    // Instrucciones validas en Execute
    input wire valid0E,
    input wire valid1E,

    // Datos de ambas vias en Execute
    input wire [WIDTH-1:0] data0E,
    input wire [WIDTH-1:0] data1E,

    // Instrucciones validas en Memory
    output reg valid0M,
    output reg valid1M,

    // Datos registrados para Memory
    output reg [WIDTH-1:0] data0M,
    output reg [WIDTH-1:0] data1M
);

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            valid0M <= 1'b0;
            valid1M <= 1'b0;

            data0M <= {WIDTH{1'b0}};
            data1M <= {WIDTH{1'b0}};
        end

        else if (enable) begin
            valid0M <= valid0E && !flush0;
            valid1M <= valid1E && !flush1;

            data0M <= flush0 ? {WIDTH{1'b0}} : data0E;
            data1M <= flush1 ? {WIDTH{1'b0}} : data1E;
        end

    end

endmodule
