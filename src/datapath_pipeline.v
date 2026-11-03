module datapath_pipeline (
    input clk, reset,
    output [31:0] PC,
    input [31:0] Instr,
    output MemWrite,
    output [31:0] DataAdr, WriteData,
    input [31:0] ReadData
);

    wire [31:0] PCF, PCPlus4F, PCNextF;
    wire [31:0] PCD, InstrD;
    wire [31:0] PCTargetE;
    wire PCSrcE;

    wire StallF, StallD, FlushD, FlushE;

    assign PCPlus4F = PCF + 32'd4;

    assign PCNextF = PCSrcE ? PCTargetE :
                     StallF ? PCF : PCPlus4F;

    flopr #(32) pcreg (
        .clk(clk),
        .reset(reset),
        .d(PCNextF),
        .q(PCF)
    );

    assign PC = PCF;

    ifid reg_ifid (
        .clk(clk),
        .reset(reset),
        .enable(~StallD),
        .flush(FlushD),
        .PCF(PCF),
        .InstrF(Instr),
        .PCD(PCD),
        .InstrD(InstrD)
    );

    wire RegWriteD, MemWriteD, ALUSrcD;
    wire JumpD, BranchD;
    wire [1:0] ResultSrcD, ImmSrcD;
    wire [3:0] ALUControlD;

    wire [31:0] RD1D, RD2D, ImmExtD;
    wire [31:0] ResultW;
    wire [4:0] RdW;
    wire RegWriteW;

    controller control (
        .op(InstrD[6:0]),
        .funct3(InstrD[14:12]),
        .funct7b5(InstrD[30]),
        .ResultSrc(ResultSrcD),
        .MemWrite(MemWriteD),
        .ALUSrc(ALUSrcD),
        .RegWrite(RegWriteD),
        .Jump(JumpD),
        .Branch(BranchD),
        .ImmSrc(ImmSrcD),
        .ALUControl(ALUControlD)
    );

    regfile rf (
        .clk(clk),
        .we3(RegWriteW && (RdW != 5'd0)),
        .a1(InstrD[19:15]),
        .a2(InstrD[24:20]),
        .a3(RdW),
        .wd3(ResultW),
        .rd1(RD1D),
        .rd2(RD2D)
    );

    extend ext (
        .instr(InstrD[31:7]),
        .immsrc(ImmSrcD),
        .immext(ImmExtD)
    );

    wire [31:0] PCE, RD1E, RD2E, ImmExtE;
    wire [4:0] Rs1E, Rs2E, RdE;

    wire RegWriteE, MemWriteE, ALUSrcE;
    wire BranchE, JumpE;
    wire [1:0] ResultSrcE;
    wire [3:0] ALUControlE;

    idex reg_idex (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .flush(FlushE),

        .PCD(PCD),
        .RD1D(RD1D),
        .RD2D(RD2D),
        .ImmExtD(ImmExtD),

        .Rs1D(InstrD[19:15]),
        .Rs2D(InstrD[24:20]),
        .RdD(InstrD[11:7]),

        .RegWriteD(RegWriteD),
        .MemWriteD(MemWriteD),
        .ALUSrcD(ALUSrcD),
        .BranchD(BranchD),
        .JumpD(JumpD),
        .ResultSrcD(ResultSrcD),
        .ALUControlD(ALUControlD),

        .PCE(PCE),
        .RD1E(RD1E),
        .RD2E(RD2E),
        .ImmExtE(ImmExtE),

        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdE(RdE),

        .RegWriteE(RegWriteE),
        .MemWriteE(MemWriteE),
        .ALUSrcE(ALUSrcE),
        .BranchE(BranchE),
        .JumpE(JumpE),
        .ResultSrcE(ResultSrcE),
        .ALUControlE(ALUControlE)
    );

    wire [31:0] SrcBE;
    wire [31:0] ALUResultE;
    wire [31:0] PCPlus4E;
    wire ZeroE;
    
    assign SrcBE = ALUSrcE ? ImmExtE : ForwardedRD2E;
    
    assign PCPlus4E = PCE + 32'd4;

    assign PCTargetE = PCE + ImmExtE;

    alu alu_unit (
        .a(SrcAE),
        .b(SrcBE),
        .alucontrol(ALUControlE),
        .result(ALUResultE),
        .zero(ZeroE)
    );

    assign PCSrcE = JumpE | (BranchE & ZeroE);

    wire [31:0] ALUResultM, WriteDataM;
    wire [31:0] PCPlus4M;
    wire [4:0] RdM;

    wire RegWriteM, MemWriteM;
    wire [1:0] ResultSrcM;

    exmem reg_exmem (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .flush(1'b0),

        .ALUResultE(ALUResultE),
        .RD2E(ForwardedRD2E),
        .PCPlus4E(PCPlus4E),
        .RdE(RdE),

        .RegWriteE(RegWriteE),
        .MemWriteE(MemWriteE),
        .ResultSrcE(ResultSrcE),

        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),
        .PCPlus4M(PCPlus4M),
        .RdM(RdM),

        .RegWriteM(RegWriteM),
        .MemWriteM(MemWriteM),
        .ResultSrcM(ResultSrcM)
    );

    assign DataAdr = ALUResultM;
    assign WriteData = WriteDataM;
    assign MemWrite = MemWriteM;

    wire [31:0] ALUResultW, ReadDataW;
    wire [31:0] PCPlus4W;

    wire [1:0] ResultSrcW;

    memwb reg_memwb (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .flush(1'b0),

        .ALUResultM(ALUResultM),
        .ReadDataM(ReadData),
        .PCPlus4M(PCPlus4M),
        .RdM(RdM),

        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),

        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .PCPlus4W(PCPlus4W),
        .RdW(RdW),

        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW)
    );

    mux3 #(32) result_mux (
        .d0(ALUResultW),
        .d1(ReadDataW),
        .d2(PCPlus4W),
        .s(ResultSrcW),
        .y(ResultW)
    );
    
    wire UsesRs1D, UsesRs2D;

     assign UsesRs1D =
    (InstrD[6:0] == 7'b0110011) ||
    (InstrD[6:0] == 7'b0010011) ||
    (InstrD[6:0] == 7'b0000011) ||
    (InstrD[6:0] == 7'b0100011) ||
    (InstrD[6:0] == 7'b1100011);

    assign UsesRs2D =
    (InstrD[6:0] == 7'b0110011) ||
    (InstrD[6:0] == 7'b0100011) ||
    (InstrD[6:0] == 7'b1100011);

     hazard_unit hu (
    .Rs1D(InstrD[19:15]),
    .Rs2D(InstrD[24:20]),
    .UsesRs1D(UsesRs1D),
    .UsesRs2D(UsesRs2D),

    .RdE(RdE),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .PCSrcE(PCSrcE),

    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE)
);

    wire [1:0] ForwardAE, ForwardBE;
    wire [31:0] SrcAE, ForwardedRD2E;
    wire [31:0] ForwardResultM;
    
    assign ForwardResultM =
        (ResultSrcM == 2'b10) ? PCPlus4M : ALUResultM;
    
    forwarding_unit fu (
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdM(RdM),
        .RdW(RdW),
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .ResultSrcM(ResultSrcM),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE)
    );
    
    assign SrcAE =
        (ForwardAE == 2'b10) ? ForwardResultM :
        (ForwardAE == 2'b01) ? ResultW :
                              RD1E;
    
    assign ForwardedRD2E =
        (ForwardBE == 2'b10) ? ForwardResultM :
        (ForwardBE == 2'b01) ? ResultW :
                              RD2E;

endmodule
