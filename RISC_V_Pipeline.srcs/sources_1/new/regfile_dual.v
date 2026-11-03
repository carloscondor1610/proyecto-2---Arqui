
`timescale 1ns / 1ps

module regfile_dual (
    input wire clk,

    // Puerto de escritura para pruebas
    input wire we,
    input wire [4:0] wa,
    input wire [31:0] wd,

    // Dos lecturas para instruccion 0
    input wire [4:0] a1_0,
    input wire [4:0] a2_0,

    // Dos lecturas para instruccion 1
    input wire [4:0] a1_1,
    input wire [4:0] a2_1,

    // Cuatro salidas de lectura
    output wire [31:0] rd1_0,
    output wire [31:0] rd2_0,
    output wire [31:0] rd1_1,
    output wire [31:0] rd2_1
);

    // Banco de 32 registros de 32 bits
    reg [31:0] rf [0:31];

    // Escritura de prueba
    always @(posedge clk) begin
        if (we && wa != 5'd0)
            rf[wa] <= wd;
    end

    // Lectura de operandos de instruccion 0
    assign rd1_0 = (a1_0 == 5'd0) ? 32'd0 :
                   (we && wa == a1_0) ? wd :
                   rf[a1_0];

    assign rd2_0 = (a2_0 == 5'd0) ? 32'd0 :
                   (we && wa == a2_0) ? wd :
                   rf[a2_0];

    // Lectura de operandos de instruccion 1
    assign rd1_1 = (a1_1 == 5'd0) ? 32'd0 :
                   (we && wa == a1_1) ? wd :
                   rf[a1_1];

    assign rd2_1 = (a2_1 == 5'd0) ? 32'd0 :
                   (we && wa == a2_1) ? wd :
                   rf[a2_1];

endmodule
