`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2026 10:08:48 AM
// Design Name: 
// Module Name: ifid_dual
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



module ifid_dual (
    input wire clk,
    input wire reset,

    // Control del registro
    input wire stall,
    input wire flush,
    input wire shift_pending,

    // Instrucciones desde Dual Fetch
    input wire [31:0] instr0F,
    input wire [31:0] instr1F,

    // Direcciones desde Dual Fetch
    input wire [31:0] pc0F,
    input wire [31:0] pc1F,

    // Bits de validez de entrada
    input wire valid0F,
    input wire valid1F,

    // Salidas hacia Dual Decode
    output reg [31:0] instr0D,
    output reg [31:0] instr1D,

    output reg [31:0] pc0D,
    output reg [31:0] pc1D,

    output reg valid0D,
    output reg valid1D
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            instr0D <= 32'b0;
            instr1D <= 32'b0;
            pc0D <= 32'b0;
            pc1D <= 32'b0;
            valid0D <= 1'b0;
            valid1D <= 1'b0;
        end

        // Flush tiene prioridad sobre Stall
        else if (flush) begin
            instr0D <= 32'b0;
            instr1D <= 32'b0;
            pc0D <= 32'b0;
            pc1D <= 32'b0;
            valid0D <= 1'b0;
            valid1D <= 1'b0;
        end

        // Detener el registro
        else if (stall) begin
            // Conservar los valores actuales
        end

        // Solo salio la antigua. La pendiente conserva su instruccion y PC.
        else if (shift_pending) begin
            instr0D <= instr1D;
            pc0D <= pc1D;
            valid0D <= valid1D;

            instr1D <= instr0F;
            pc1D <= pc0F;
            valid1D <= valid0F;
        end

        // Llenar la ventana desde Fetch.
        else begin
            instr0D <= instr0F;
            instr1D <= instr1F;

            pc0D <= pc0F;
            pc1D <= pc1F;

            valid0D <= valid0F;
            valid1D <= valid1F;
        end
    end

endmodule

