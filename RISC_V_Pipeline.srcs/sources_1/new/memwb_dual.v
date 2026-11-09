`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2026 11:12:11 AM
// Design Name: 
// Module Name: memwb_dual
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

module memwb_dual #(
    parameter WIDTH = 104
)(
    input wire clk,
    input wire reset,
    input wire enable,

    // Instrucciones validas en Memory
    input wire valid0M,
    input wire valid1M,

    // Datos de ambas vias en Memory
    input wire [WIDTH-1:0] data0M,
    input wire [WIDTH-1:0] data1M,

    // Instrucciones validas en Writeback
    output reg valid0W,
    output reg valid1W,

    // Datos registrados para Writeback
    output reg [WIDTH-1:0] data0W,
    output reg [WIDTH-1:0] data1W
);

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            valid0W <= 1'b0;
            valid1W <= 1'b0;

            data0W <= {WIDTH{1'b0}};
            data1W <= {WIDTH{1'b0}};
        end

        else if (enable) begin
            valid0W <= valid0M;
            valid1W <= valid1M;

            data0W <= data0M;
            data1W <= data1M;
        end

    end

endmodule
