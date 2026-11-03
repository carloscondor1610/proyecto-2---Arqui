`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2026 09:01:39 AM
// Design Name: 
// Module Name: dual_fetch
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


module dual_fetch (
    input wire clk, reset,
    input wire [1:0] advance,
    input wire redirect,
    input wire [31:0] redirect_pc,

    output reg [31:0] pc,
    output wire [31:0] pc1,
    output wire [31:0] instr0, instr1
);

    // Direccion de la segunda instruccion
    assign pc1 = pc + 32'd4;

    // Actualizacion secuencial del PC
    wire [31:0] next_sequential =
        pc + ((advance == 2'd2) ? 32'd8 :
              (advance == 2'd1) ? 32'd4 :
                                   32'd0);

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'd0;
        else if (redirect)
            pc <= redirect_pc;
        else
            pc <= next_sequential;
    end

    // Memoria de instrucciones Dual Fetch
    imem_dual mem_inst (
        .addr0(pc),
        .addr1(pc1),
        .instr0(instr0),
        .instr1(instr1)
    );

endmodule
