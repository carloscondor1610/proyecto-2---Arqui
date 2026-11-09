
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
    
        // Tipo de operacion de memoria
    wire [2:0] funct3_0D = instr0D[14:12];
    wire [2:0] funct3_1D = instr1D[14:12];

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

        // ======================================
    // 4. REGISTER FILE DUAL
    // ======================================

    regfile_dual rf_unit (
        .clk(clk),

        // Escritura de la via 0 desde WB
        .we0(RegWriteEnable0W),
        .wa0(rd_0W),
        .wd0(Result0W),

        // Escritura de la via 1 desde WB
        .we1(RegWriteEnable1W),
        .wa1(rd_1W),
        .wd1(Result1W),

        // Lectura de la via 0
        .a1_0(rs1_0),
        .a2_0(rs2_0),

        // Lectura de la via 1
        .a1_1(rs1_1),
        .a2_1(rs2_1),

        // Cuatro resultados de lectura
        .rd1_0(RD1_0),
        .rd2_0(RD2_0),
        .rd1_1(RD1_1),
        .rd2_1(RD2_1)
    );
    
        // ======================================
    // 4.1 REGISTRO ID/EX DUAL
    // ======================================

    localparam IDEX_WIDTH = 157;

    wire valid0E, valid1E;

    wire [IDEX_WIDTH-1:0] data0E;
    wire [IDEX_WIDTH-1:0] data1E;

    wire [IDEX_WIDTH-1:0] data0D;
    wire [IDEX_WIDTH-1:0] data1D;

    // Empaquetar datos y control de la via 0
    assign data0D = {
        pc0D,
        RD1_0,
        RD2_0,
        immext0,
        rs1_0,
        rs2_0,
        rd_0,
        ResultSrc0,
        MemWrite0,
        ALUSrc0,
        RegWrite0,
        Jump0,
        Branch0,
        ALUControl0,
        funct3_0D
    };

    // Empaquetar datos y control de la via 1
    assign data1D = {
        pc1D,
        RD1_1,
        RD2_1,
        immext1,
        rs1_1,
        rs2_1,
        rd_1,
        ResultSrc1,
        MemWrite1,
        ALUSrc1,
        RegWrite1,
        Jump1,
        Branch1,
        ALUControl1,
        funct3_1D
    };

    // Registro de pipeline para ambas vias
    idex_dual #(
        .WIDTH(IDEX_WIDTH)
    ) idex_unit (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .flush(1'b0),

        .valid0D(valid0D),
        .valid1D(valid1D),

        .data0D(data0D),
        .data1D(data1D),

        .valid0E(valid0E),
        .valid1E(valid1E),

        .data0E(data0E),
        .data1E(data1E)
    );
    
    // ======================================
    // 5. OPERANDOS DE LAS DOS ALU
    // ======================================
    
        // ======================================
    // DESEMPAQUETADO ID/EX - VIA 0
    // ======================================

    wire[2:0] funct3_0E;

    wire [31:0] pc0E;
    wire [31:0] RD1_0E, RD2_0E;
    wire [31:0] immext0E;

    wire [4:0] rs1_0E, rs2_0E, rd_0E;
    wire [1:0] ResultSrc0E;

    wire MemWrite0E, ALUSrc0E, RegWrite0E;
    wire Jump0E, Branch0E;
    wire [3:0] ALUControl0E;

    assign {
        pc0E,
        RD1_0E,
        RD2_0E,
        immext0E,
        rs1_0E,
        rs2_0E,
        rd_0E,
        ResultSrc0E,
        MemWrite0E,
        ALUSrc0E,
        RegWrite0E,
        Jump0E,
        Branch0E,
        ALUControl0E,
        funct3_0E
    } = data0E;

    // ======================================
    // DESEMPAQUETADO ID/EX - VIA 1
    // ======================================
    wire [2:0] funct3_1E;

    wire [31:0] pc1E;
    wire [31:0] RD1_1E, RD2_1E;
    wire [31:0] immext1E;

    wire [4:0] rs1_1E, rs2_1E, rd_1E;
    wire [1:0] ResultSrc1E;

    wire MemWrite1E, ALUSrc1E, RegWrite1E;
    wire Jump1E, Branch1E;
    wire [3:0] ALUControl1E;

    assign {
        pc1E,
        RD1_1E,
        RD2_1E,
        immext1E,
        rs1_1E,
        rs2_1E,
        rd_1E,
        ResultSrc1E,
        MemWrite1E,
        ALUSrc1E,
        RegWrite1E,
        Jump1E,
        Branch1E,
        ALUControl1E,
        funct3_1E
    } = data1E;

    // ======================================
    // OPERANDOS ALU - ETAPA EXECUTE
    // ======================================

    wire [31:0] SrcA0 = RD1_0E;

    wire [31:0] SrcB0 =
        ALUSrc0E ? immext0E : RD2_0E;

    wire [31:0] SrcA1 = RD1_1E;

    wire [31:0] SrcB1 =
        ALUSrc1E ? immext1E : RD2_1E;
        
    wire Zero0, Zero1;

        // ALU de la via 0
    alu alu0 (
        .a(SrcA0),
        .b(SrcB0),
        .alucontrol(ALUControl0E),
        .result(result0),
        .zero(Zero0)
    );

    // ALU de la via 1
    alu alu1 (
        .a(SrcA1),
        .b(SrcB1),
        .alucontrol(ALUControl1E),
        .result(result1),
        .zero(Zero1)
    );
    
    
        // ======================================
    // 6. REGISTRO EX/MEM DUAL
    // ======================================

    localparam EXMEM_WIDTH = 108;

    // Datos de entrada desde Execute
    wire [EXMEM_WIDTH-1:0] data0E_exmem;
    wire [EXMEM_WIDTH-1:0] data1E_exmem;

    // Datos de salida hacia Memory
    wire [EXMEM_WIDTH-1:0] data0M;
    wire [EXMEM_WIDTH-1:0] data1M;

    wire valid0M, valid1M;

    // Empaquetado de la via 0
    assign data0E_exmem = {
        pc0E,
        result0,
        RD2_0E,
        rd_0E,
        ResultSrc0E,
        MemWrite0E,
        RegWrite0E,
        funct3_0E
    };

    // Empaquetado de la via 1
    assign data1E_exmem = {
        pc1E,
        result1,
        RD2_1E,
        rd_1E,
        ResultSrc1E,
        MemWrite1E,
        RegWrite1E,
        funct3_1E
    };

    // Registro EX/MEM para ambas vias
    exmem_dual #(
        .WIDTH(EXMEM_WIDTH)
    ) exmem_unit (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),

        .flush0(1'b0),
        .flush1(1'b0),

        .valid0E(valid0E),
        .valid1E(valid1E),

        .data0E(data0E_exmem),
        .data1E(data1E_exmem),

        .valid0M(valid0M),
        .valid1M(valid1M),

        .data0M(data0M),
        .data1M(data1M)
    );
        // ======================================
    // 7. DESEMPAQUETADO EX/MEM DUAL
    // ======================================
    wire [2:0] funct3_0M;
    wire [2:0] funct3_1M;
    
    
    // Via 0
    wire [31:0] pc0M;
    wire [31:0] ALUResult0M;
    wire [31:0] WriteData0M;
    wire [4:0] rd_0M;
    wire [1:0] ResultSrc0M;
    wire MemWrite0M, RegWrite0M;

    assign {
        pc0M,
        ALUResult0M,
        WriteData0M,
        rd_0M,
        ResultSrc0M,
        MemWrite0M,
        RegWrite0M,
        funct3_0M
    } = data0M;

    // Via 1
    wire [31:0] pc1M;
    wire [31:0] ALUResult1M;
    wire [31:0] WriteData1M;
    wire [4:0] rd_1M;
    wire [1:0] ResultSrc1M;
    wire MemWrite1M, RegWrite1M;

    assign {
        pc1M,
        ALUResult1M,
        WriteData1M,
        rd_1M,
        ResultSrc1M,
        MemWrite1M,
        RegWrite1M,
        funct3_1M
    } = data1M;
    
    
        // ======================================
    // 8. MEMORIA DE DATOS COMPARTIDA
    // ======================================

    // ResultSrc = 01 indica lectura de memoria.
    wire MemRead0M = valid0M && (ResultSrc0M == 2'b01);
    wire MemRead1M = valid1M && (ResultSrc1M == 2'b01);

    wire MemAccess0M = valid0M &&
                       (MemWrite0M || MemRead0M);

    wire MemAccess1M = valid1M &&
                       (MemWrite1M || MemRead1M);

    // Detectar dos accesos simultaneos
    wire mem_conflict = MemAccess0M && MemAccess1M;

    // Seleccion del puerto compartido
    wire select_mem1 = !MemAccess0M && MemAccess1M;

    wire [31:0] MemAddress =
        select_mem1 ? ALUResult1M : ALUResult0M;

    wire [31:0] MemWriteData =
        select_mem1 ? WriteData1M : WriteData0M;

    wire MemWrite =
        (MemAccess0M && MemWrite0M) ||
        (select_mem1 && MemWrite1M);

    wire [31:0] ReadDataM;
    wire [2:0] MemFunct3 = select_mem1 ? funct3_1M : funct3_0M;

    // Memoria de datos de un solo puerto
    dmem_dual dmem_unit (
    .clk(clk),
    .memwrite(MemWrite),
    .address(MemAddress),
    .writedata(MemWriteData),
    .funct3(MemFunct3),
    .readdata(ReadDataM)
    );

    // Resultado de lectura por via
    wire [31:0] ReadData0M =
        MemRead0M ? ReadDataM : 32'd0;

    wire [31:0] ReadData1M =
        (MemRead1M && select_mem1) ?
        ReadDataM : 32'd0;
        
        
        // ======================================
    // 9. REGISTRO MEM/WB DUAL
    // ======================================

    localparam MEMWB_WIDTH = 104;

    // Datos de entrada desde Memory
    wire [MEMWB_WIDTH-1:0] data0M_memwb;
    wire [MEMWB_WIDTH-1:0] data1M_memwb;

    // Datos de salida hacia Writeback
    wire [MEMWB_WIDTH-1:0] data0W;
    wire [MEMWB_WIDTH-1:0] data1W;

    wire valid0W, valid1W;

    // Empaquetado de la via 0
    assign data0M_memwb = {
        pc0M,
        ALUResult0M,
        ReadData0M,
        rd_0M,
        ResultSrc0M,
        RegWrite0M
    };

    // Empaquetado de la via 1
    assign data1M_memwb = {
        pc1M,
        ALUResult1M,
        ReadData1M,
        rd_1M,
        ResultSrc1M,
        RegWrite1M
    };

    // Registro MEM/WB para ambas vias
    memwb_dual #(
        .WIDTH(MEMWB_WIDTH)
    ) memwb_unit (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),

        .valid0M(valid0M),
        .valid1M(valid1M),

        .data0M(data0M_memwb),
        .data1M(data1M_memwb),

        .valid0W(valid0W),
        .valid1W(valid1W),

        .data0W(data0W),
        .data1W(data1W)
    );
    
        // ======================================
    // 10. DESEMPAQUETADO MEM/WB DUAL
    // ======================================

    // Via 0
    wire [31:0] pc0W;
    wire [31:0] ALUResult0W;
    wire [31:0] ReadData0W;
    wire [4:0] rd_0W;
    wire [1:0] ResultSrc0W;
    wire RegWrite0W;

    assign {
        pc0W,
        ALUResult0W,
        ReadData0W,
        rd_0W,
        ResultSrc0W,
        RegWrite0W
    } = data0W;

    // Via 1
    wire [31:0] pc1W;
    wire [31:0] ALUResult1W;
    wire [31:0] ReadData1W;
    wire [4:0] rd_1W;
    wire [1:0] ResultSrc1W;
    wire RegWrite1W;

    assign {
        pc1W,
        ALUResult1W,
        ReadData1W,
        rd_1W,
        ResultSrc1W,
        RegWrite1W
    } = data1W;

    // ======================================
    // 11. RESULTADOS DE WRITEBACK
    // ======================================

    // Seleccion del resultado final de cada via
    // 00: ALU
    // 01: Memoria
    // 10: PC + 4 (JAL/JALR)

    wire [31:0] Result0W;
    wire [31:0] Result1W;

    assign Result0W =
        (ResultSrc0W == 2'b00) ? ALUResult0W :
        (ResultSrc0W == 2'b01) ? ReadData0W :
        (ResultSrc0W == 2'b10) ? (pc0W + 32'd4) :
        32'd0;

    assign Result1W =
        (ResultSrc1W == 2'b00) ? ALUResult1W :
        (ResultSrc1W == 2'b01) ? ReadData1W :
        (ResultSrc1W == 2'b10) ? (pc1W + 32'd4) :
        32'd0;

    // Habilitacion de escritura por via
    wire RegWriteEnable0W;
    wire RegWriteEnable1W;

    assign RegWriteEnable0W = valid0W && RegWrite0W;
    assign RegWriteEnable1W = valid1W && RegWrite1W;
endmodule
