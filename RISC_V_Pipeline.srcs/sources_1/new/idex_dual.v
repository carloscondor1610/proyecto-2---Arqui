`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2026 11:07:48 AM
// Design Name: 
// Module Name: idex_dual
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

module idex_dual #(
    parameter WIDTH = 154
)(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire flush,

    // Instrucciones validas en Decode
    input wire valid0D,
    input wire valid1D,

    // Datos de ambas vias
    input wire [WIDTH-1:0] data0D,
    input wire [WIDTH-1:0] data1D,

    // Instrucciones validas en Execute
    output reg valid0E,
    output reg valid1E,

    // Datos registrados para Execute
    output reg [WIDTH-1:0] data0E,
    output reg [WIDTH-1:0] data1E
);

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            valid0E <= 1'b0;
            valid1E <= 1'b0;

            data0E <= {WIDTH{1'b0}};
            data1E <= {WIDTH{1'b0}};
        end

        else if (flush) begin
            valid0E <= 1'b0;
            valid1E <= 1'b0;

            data0E <= {WIDTH{1'b0}};
            data1E <= {WIDTH{1'b0}};
        end

        else if (enable) begin
            valid0E <= valid0D;
            valid1E <= valid1D;

            data0E <= data0D;
            data1E <= data1D;
        end

    end

endmodule
