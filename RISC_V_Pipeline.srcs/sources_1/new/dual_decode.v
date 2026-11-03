`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2026 10:05:51 AM
// Design Name: 
// Module Name: dual_decode
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



module dual_decode (
    input wire [31:0] instr0,
    input wire [31:0] instr1,

    // Registros de la instruccion 0
    output wire [4:0] rs1_0,
    output wire [4:0] rs2_0,
    output wire [4:0] rd_0,

    // Registros de la instruccion 1
    output wire [4:0] rs1_1,
    output wire [4:0] rs2_1,
    output wire [4:0] rd_1,

    // Inmediatos extendidos
    output wire [31:0] immext0,
    output wire [31:0] immext1,

    // Control instruccion 0
    output wire [1:0] ResultSrc0,
    output wire MemWrite0,
    output wire ALUSrc0,
    output wire RegWrite0,
    output wire Jump0,
    output wire Branch0,
    output wire [3:0] ALUControl0,

    // Control instruccion 1
    output wire [1:0] ResultSrc1,
    output wire MemWrite1,
    output wire ALUSrc1,
    output wire RegWrite1,
    output wire Jump1,
    output wire Branch1,
    output wire [3:0] ALUControl1
);

    wire [1:0] ImmSrc0;
    wire [1:0] ImmSrc1;

    // ==========================================
    // INSTRUCCION 0
    // ==========================================

    assign rs1_0 = instr0[19:15];
    assign rs2_0 = instr0[24:20];
    assign rd_0  = instr0[11:7];

    controller controller0 (
        .op(instr0[6:0]),
        .funct3(instr0[14:12]),
        .funct7b5(instr0[30]),

        .ResultSrc(ResultSrc0),
        .MemWrite(MemWrite0),
        .ALUSrc(ALUSrc0),
        .RegWrite(RegWrite0),
        .Jump(Jump0),
        .Branch(Branch0),
        .ImmSrc(ImmSrc0),
        .ALUControl(ALUControl0)
    );

    extend extend0 (
        .instr(instr0[31:7]),
        .immsrc(ImmSrc0),
        .immext(immext0)
    );

    // ==========================================
    // INSTRUCCION 1
    // ==========================================

    assign rs1_1 = instr1[19:15];
    assign rs2_1 = instr1[24:20];
    assign rd_1  = instr1[11:7];

    controller controller1 (
        .op(instr1[6:0]),
        .funct3(instr1[14:12]),
        .funct7b5(instr1[30]),

        .ResultSrc(ResultSrc1),
        .MemWrite(MemWrite1),
        .ALUSrc(ALUSrc1),
        .RegWrite(RegWrite1),
        .Jump(Jump1),
        .Branch(Branch1),
        .ImmSrc(ImmSrc1),
        .ALUControl(ALUControl1)
    );

    extend extend1 (
        .instr(instr1[31:7]),
        .immsrc(ImmSrc1),
        .immext(immext1)
    );

endmodule