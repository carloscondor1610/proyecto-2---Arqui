
`timescale 1ns / 1ps

module datapath_dual (
    input wire clk,
    input wire reset,

    // Control preliminar del Fetch
    input wire [1:0] advance,
    input wire redirect,
    input wire [31:0] redirect_pc,
    input wire stallD,
    input wire flushD,

    // Puerto de escritura para pruebas del Register File
    input wire we_test,
    input wire [4:0] wa_test,
    input wire [31:0] wd_test,

    // Salidas observables
    output wire [31:0] pcF,
    output wire [31:0] pc1F,
    output wire [31:0] instr0D,
    output wire [31:0] instr1D,
    output wire valid0D,
    output wire valid1D,
    output wire [31:0] result0,
    output wire [31:0] result1
);

    // ======================================
    // 1. DUAL FETCH
    // ======================================

    wire [31:0] instr0F, instr1F;

    dual_fetch fetch_unit (
        .clk(clk),
        .reset(reset),
        .advance(advance),
        .redirect(redirect),
        .redirect_pc(redirect_pc),
        .pc(pcF),
        .pc1(pc1F),
        .instr0(instr0F),
        .instr1(instr1F)
    );

    // ======================================
    // 2. IF/ID DUAL
    // ======================================

    wire [31:0] pc0D, pc1D;

    // La captura se habilita segun advance.
    wire valid0F = (advance != 2'd0);
    wire valid1F = (advance == 2'd2);

    ifid_dual ifid_unit (
        .clk(clk),
        .reset(reset),
        .stall(stallD | (advance == 2'd0)),
        .flush(flushD | redirect),

        .instr0F(instr0F),
        .instr1F(instr1F),
        .pc0F(pcF),
        .pc1F(pc1F),

        .valid0F(valid0F),
        .valid1F(valid1F),

        .instr0D(instr0D),
        .instr1D(instr1D),
        .pc0D(pc0D),
        .pc1D(pc1D),
        .valid0D(valid0D),
        .valid1D(valid1D)
    );

    // ======================================
    // 3. DUAL DECODE
    // ======================================

    wire [4:0] rs1_0, rs2_0, rd_0;
    wire [4:0] rs1_1, rs2_1, rd_1;

    wire [31:0] immext0, immext1;

    wire [1:0] ResultSrc0, ResultSrc1;
    wire MemWrite0, MemWrite1;
    wire ALUSrc0, ALUSrc1;
    wire RegWrite0, RegWrite1;
    wire Jump0, Jump1;
    wire Branch0, Branch1;
    wire [3:0] ALUControl0, ALUControl1;

    dual_decode decode_unit (
        .instr0(instr0D),
        .instr1(instr1D),

        .rs1_0(rs1_0),
        .rs2_0(rs2_0),
        .rd_0(rd_0),

        .rs1_1(rs1_1),
        .rs2_1(rs2_1),
        .rd_1(rd_1),

        .immext0(immext0),
        .immext1(immext1),

        .ResultSrc0(ResultSrc0),
        .MemWrite0(MemWrite0),
        .ALUSrc0(ALUSrc0),
        .RegWrite0(RegWrite0),
        .Jump0(Jump0),
        .Branch0(Branch0),
        .ALUControl0(ALUControl0),

        .ResultSrc1(ResultSrc1),
        .MemWrite1(MemWrite1),
        .ALUSrc1(ALUSrc1),
        .RegWrite1(RegWrite1),
        .Jump1(Jump1),
        .Branch1(Branch1),
        .ALUControl1(ALUControl1)
    );

    // ======================================
    // 4. REGISTER FILE PRELIMINAR
    // ======================================

    wire [31:0] RD1_0, RD2_0;
    wire [31:0] RD1_1, RD2_1;

    regfile_dual rf_unit (
        .clk(clk),
        .we(we_test),
        .wa(wa_test),
        .wd(wd_test),

        .a1_0(rs1_0),
        .a2_0(rs2_0),
        .a1_1(rs1_1),
        .a2_1(rs2_1),

        .rd1_0(RD1_0),
        .rd2_0(RD2_0),
        .rd1_1(RD1_1),
        .rd2_1(RD2_1)
    );

    // ======================================
    // 5. OPERANDOS DE LAS DOS ALU
    // ======================================

    wire [31:0] SrcA0 = RD1_0;
    wire [31:0] SrcB0 =
        ALUSrc0 ? immext0 : RD2_0;

    wire [31:0] SrcA1 = RD1_1;
    wire [31:0] SrcB1 =
        ALUSrc1 ? immext1 : RD2_1;

    wire Zero0, Zero1;

    // ======================================
    // 6. ALU DE LA VIA 0
    // ======================================

    alu alu0 (
        .a(SrcA0),
        .b(SrcB0),
        .alucontrol(ALUControl0),
        .result(result0),
        .zero(Zero0)
    );

    // ======================================
    // 7. ALU DE LA VIA 1
    // ======================================

    alu alu1 (
        .a(SrcA1),
        .b(SrcB1),
        .alucontrol(ALUControl1),
        .result(result1),
        .zero(Zero1)
    );

endmodule
