
`timescale 1ns / 1ps

module datapath_dual (
    input wire clk,
    input wire reset,

    input wire [1:0] advance,
    input wire redirect,
    input wire [31:0] redirect_pc,
    input wire stallD,
    input wire flushD,

    input wire we_test,
    input wire [4:0] wa_test,
    input wire [31:0] wd_test,

    output wire [31:0] pcF,
    output wire [31:0] pc1F,
    output wire [31:0] instr0D,
    output wire [31:0] instr1D,
    output wire valid0D,
    output wire valid1D,
    output wire [31:0] result0,
    output wire [31:0] result1
);

    wire StallF_H, StallD_H, FlushD_H, FlushE_H;
    wire UsesRs1E1, UsesRs2E1;
    wire valid0M, valid1M;
    wire [4:0] rd_0M;
    wire [1:0] ResultSrc0M;
    wire MemWrite0M, RegWrite0M;
    wire [4:0] rd_1M;
    wire [1:0] ResultSrc1M;
    wire MemWrite1M, RegWrite1M;
    wire valid0W, valid1W;
    wire [4:0] rd_0W;
    wire RegWrite0W;
    wire [4:0] rd_1W;
    wire RegWrite1W;
    wire [31:0] Result0W;
    wire [31:0] Result1W;
    wire RegWriteEnable0W;
    wire RegWriteEnable1W;
    wire UsesRs1E0, UsesRs2E0;

    wire [31:0] instr0F, instr1F;
    wire branchRedirect;
    wire [31:0] branchTargetE;

    dual_fetch fetch_unit (
        .clk(clk),
        .reset(reset),
        .advance(StallF_H ? 2'd0 : advance),
        .redirect(branchRedirect),
        .redirect_pc(redirect ? redirect_pc : branchTargetE),
        .pc(pcF),
        .pc1(pc1F),
        .instr0(instr0F),
        .instr1(instr1F)
    );

    wire [31:0] pc0D, pc1D;

    wire valid0F = (advance != 2'd0);
    wire valid1F = (advance == 2'd2);

    ifid_dual ifid_unit (
        .clk(clk),
        .reset(reset),
        .stall(stallD | StallD_H | (advance == 2'd0)),
        .flush(flushD | FlushD_H | branchRedirect),

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

    wire [4:0] rs1_0, rs2_0, rd_0;
    wire [4:0] rs1_1, rs2_1, rd_1;

    wire [2:0] funct3_0D = instr0D[14:12];
    wire [2:0] funct3_1D = instr1D[14:12];

    wire [31:0] immext0, immext1;
    wire UsesRs1D0 = (instr0D[6:0] == 7'b0110011) || (instr0D[6:0] == 7'b0010011) ||
                      (instr0D[6:0] == 7'b0000011) || (instr0D[6:0] == 7'b0100011) ||
                      (instr0D[6:0] == 7'b1100011) || (instr0D[6:0] == 7'b1100111);
    wire UsesRs2D0 = (instr0D[6:0] == 7'b0110011) || (instr0D[6:0] == 7'b0100011) ||
                      (instr0D[6:0] == 7'b1100011);
    wire UsesRs1D1 = (instr1D[6:0] == 7'b0110011) || (instr1D[6:0] == 7'b0010011) ||
                      (instr1D[6:0] == 7'b0000011) || (instr1D[6:0] == 7'b0100011) ||
                      (instr1D[6:0] == 7'b1100011) || (instr1D[6:0] == 7'b1100111);
    wire UsesRs2D1 = (instr1D[6:0] == 7'b0110011) || (instr1D[6:0] == 7'b0100011) ||
                      (instr1D[6:0] == 7'b1100011);
    wire RAWPair, LoadUseHazard0, LoadUseHazard1;
    wire BlockIssue0, BlockIssue1;
    wire StallBoth, IssueOnly0;
    wire Issue0, Issue1;
    wire HoldDecode, PartialIssue;
    wire [1:0] IssueCount;
    wire MemCandidate0 = valid0D && (MemWrite0 || (ResultSrc0 == 2'b01));
    wire MemCandidate1 = valid1D && (MemWrite1 || (ResultSrc1 == 2'b01));
    wire MemConflictD = MemCandidate0 && MemCandidate1;
    wire BranchConflictD = valid0D && valid1D &&
                           (Branch0 || Jump0) && (Branch1 || Jump1);
    wire branchRedirectE;
    wire kill_lane1E;
    wire branch_conflictE;
    assign branchRedirect = redirect | branchRedirectE;
    wire [2:0] ForwardAE, ForwardBE, ForwardAE1, ForwardBE1;
    wire ForwardStall0, ForwardStall1;

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

    wire [31:0] RD1_0, RD2_0;
    wire [31:0] RD1_1, RD2_1;

    regfile_dual rf_unit (
        .clk(clk),

        .we0(RegWriteEnable0W),
        .wa0(rd_0W),
        .wd0(Result0W),

        .we1(RegWriteEnable1W),
        .wa1(rd_1W),
        .wd1(Result1W),

        .a1_0(rs1_0),
        .a2_0(rs2_0),

        .a1_1(rs1_1),
        .a2_1(rs2_1),

        .rd1_0(RD1_0),
        .rd2_0(RD2_0),
        .rd1_1(RD1_1),
        .rd2_1(RD2_1)
    );

    localparam IDEX_WIDTH = 159;

    wire valid0E, valid1E;

    wire [IDEX_WIDTH-1:0] data0E;
    wire [IDEX_WIDTH-1:0] data1E;

    wire [IDEX_WIDTH-1:0] data0D;
    wire [IDEX_WIDTH-1:0] data1D;

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
        funct3_0D,
        UsesRs1D0,
        UsesRs2D0
    };

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
        funct3_1D,
        UsesRs1D1,
        UsesRs2D1
    };

    idex_dual #(
        .WIDTH(IDEX_WIDTH)
    ) idex_unit (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .flush(FlushE_H | branchRedirect),
        .issue0D(1'b1),
        .issue1D(1'b1),
        .flush0(1'b0),
        .flush1(1'b0),

        .valid0D(valid0D),
        .valid1D(valid1D),

        .data0D(data0D),
        .data1D(data1D),

        .valid0E(valid0E),
        .valid1E(valid1E),

        .data0E(data0E),
        .data1E(data1E)
    );

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
        funct3_0E,
        UsesRs1E0,
        UsesRs2E0
    } = data0E;

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
        funct3_1E,
        UsesRs1E1,
        UsesRs2E1
    } = data1E;

    hazard_unit hazards (
        .Rs1D(rs1_0), .Rs2D(rs2_0), .RdD0(rd_0),
        .UsesRs1D(UsesRs1D0), .UsesRs2D(UsesRs2D0),
        .RegWriteD0(RegWrite0), .ValidD0(valid0D),
        .Rs1D1(rs1_1), .Rs2D1(rs2_1),
        .UsesRs1D1(UsesRs1D1), .UsesRs2D1(UsesRs2D1), .ValidD1(valid1D),
        .RdE(rd_0E), .RegWriteE(RegWrite0E),
        .ResultSrcE(ResultSrc0E), .ValidE0(valid0E),
        .RdE1(rd_1E), .RegWriteE1(RegWrite1E),
        .ResultSrcE1(ResultSrc1E), .ValidE1(valid1E),
        .PCSrcE(branchRedirect),
        .StallF(StallF_H), .StallD(StallD_H),
        .FlushD(FlushD_H), .FlushE(FlushE_H),
        .RAWPair(RAWPair),
        .LoadUseHazard0(LoadUseHazard0),
        .LoadUseHazard1(LoadUseHazard1),
        .BlockIssue0(BlockIssue0),
        .BlockIssue1(BlockIssue1),
        .StallBoth(StallBoth),
        .IssueOnly0(IssueOnly0)
    );

    hazard_issue_control issue_hazard_control (
        .ValidD0(valid0D),
        .ValidD1(valid1D),
        .BlockIssue0(BlockIssue0),
        .BlockIssue1(BlockIssue1),
        .MemConflict(MemConflictD),
        .BranchConflict(BranchConflictD),
        .Redirect(branchRedirect),
        .Issue0(Issue0),
        .Issue1(Issue1),
        .HoldDecode(HoldDecode),
        .PartialIssue(PartialIssue),
        .IssueCount(IssueCount)
    );

    forwarding_unit forwarding (
        .Rs1E(rs1_0E), .Rs2E(rs2_0E),
        .Rs1E1(rs1_1E), .Rs2E1(rs2_1E),
        .UsesRs1E0(UsesRs1E0), .UsesRs2E0(UsesRs2E0),
        .UsesRs1E1(UsesRs1E1), .UsesRs2E1(UsesRs2E1),
        .RdM(rd_0M), .RdM1(rd_1M),
        .RdW(rd_0W), .RdW1(rd_1W),
        .RegWriteM(RegWrite0M), .RegWriteM1(RegWrite1M),
        .RegWriteW(RegWrite0W), .RegWriteW1(RegWrite1W),
        .ValidM0(valid0M), .ValidM1(valid1M),
        .ValidW0(valid0W), .ValidW1(valid1W),
        .ResultSrcM(ResultSrc0M), .ResultSrcM1(ResultSrc1M),
        .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
        .ForwardAE1(ForwardAE1), .ForwardBE1(ForwardBE1),
        .ForwardStall0(ForwardStall0),
        .ForwardStall1(ForwardStall1)
    );

    function [31:0] bypass_data;
        input [2:0] selection;
        input [31:0] original_value;
        input [31:0] m0, m1, w0, w1;
        begin
            case (selection)
                3'd1: bypass_data = m0;
                3'd2: bypass_data = m1;
                3'd3: bypass_data = w0;
                3'd4: bypass_data = w1;
                default: bypass_data = original_value;
            endcase
        end
    endfunction

    wire [31:0] ALUForward0M = (ResultSrc0M == 2'b10) ? pc0M + 32'd4 : ALUResult0M;
    wire [31:0] ALUForward1M = (ResultSrc1M == 2'b10) ? pc1M + 32'd4 : ALUResult1M;
    wire [31:0] SrcA0 = bypass_data(ForwardAE, RD1_0E,
                                    ALUForward0M, ALUForward1M, Result0W, Result1W);
    wire [31:0] SrcA1 = bypass_data(ForwardAE1, RD1_1E,
                                    ALUForward0M, ALUForward1M, Result0W, Result1W);
    wire [31:0] RegB0 = bypass_data(ForwardBE, RD2_0E,
                                    ALUForward0M, ALUForward1M, Result0W, Result1W);
    wire [31:0] RegB1 = bypass_data(ForwardBE1, RD2_1E,
                                    ALUForward0M, ALUForward1M, Result0W, Result1W);
    wire [31:0] SrcB0 = ALUSrc0E ? immext0E : RegB0;
    wire [31:0] SrcB1 = ALUSrc1E ? immext1E : RegB1;

    wire Zero0, Zero1;

    alu alu0 (
        .a(SrcA0),
        .b(SrcB0),
        .alucontrol(ALUControl0E),
        .result(result0),
        .zero(Zero0)
    );

    alu alu1 (
        .a(SrcA1),
        .b(SrcB1),
        .alucontrol(ALUControl1E),
        .result(result1),
        .zero(Zero1)
    );

    branch_control_dual branch_controller (
        .valid0E(valid0E), .valid1E(valid1E),
        .Branch0E(Branch0E), .Branch1E(Branch1E),
        .Jump0E(Jump0E), .Jump1E(Jump1E),
        .UsesRs1E0(UsesRs1E0), .UsesRs1E1(UsesRs1E1),
        .funct3_0E(funct3_0E), .funct3_1E(funct3_1E),
        .SrcA0(SrcA0), .SrcA1(SrcA1),
        .RegB0(RegB0), .RegB1(RegB1),
        .pc0E(pc0E), .pc1E(pc1E),
        .immext0E(immext0E), .immext1E(immext1E),
        .redirectE(branchRedirectE), .redirect_pcE(branchTargetE),
        .kill_lane1E(kill_lane1E),
        .branch_conflictE(branch_conflictE)
    );

    localparam EXMEM_WIDTH = 108;

    wire [EXMEM_WIDTH-1:0] data0E_exmem;
    wire [EXMEM_WIDTH-1:0] data1E_exmem;

    wire [EXMEM_WIDTH-1:0] data0M;
    wire [EXMEM_WIDTH-1:0] data1M;

    assign data0E_exmem = {
        pc0E,
        result0,
        RegB0,
        rd_0E,
        ResultSrc0E,
        MemWrite0E,
        RegWrite0E,
        funct3_0E
    };

    assign data1E_exmem = {
        pc1E,
        result1,
        RegB1,
        rd_1E,
        ResultSrc1E,
        MemWrite1E,
        RegWrite1E,
        funct3_1E
    };

    exmem_dual #(
        .WIDTH(EXMEM_WIDTH)
    ) exmem_unit (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),

        .flush0(1'b0),
        .flush1(kill_lane1E),

        .valid0E(valid0E),
        .valid1E(valid1E),

        .data0E(data0E_exmem),
        .data1E(data1E_exmem),

        .valid0M(valid0M),
        .valid1M(valid1M),

        .data0M(data0M),
        .data1M(data1M)
    );

    wire [2:0] funct3_0M;
    wire [2:0] funct3_1M;

    wire [31:0] pc0M;
    wire [31:0] ALUResult0M;
    wire [31:0] WriteData0M;

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

    wire [31:0] pc1M;
    wire [31:0] ALUResult1M;
    wire [31:0] WriteData1M;

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

    wire MemRead0M = valid0M && (ResultSrc0M == 2'b01);
    wire MemRead1M = valid1M && (ResultSrc1M == 2'b01);

    wire MemAccess0M = valid0M &&
                       (MemWrite0M || MemRead0M);

    wire MemAccess1M = valid1M &&
                       (MemWrite1M || MemRead1M);

    wire mem_conflict = MemAccess0M && MemAccess1M;

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

    dmem_dual dmem_unit (
        .clk(clk),
        .memwrite(MemWrite),
        .address(MemAddress),
        .writedata(MemWriteData),
        .funct3(MemFunct3),
        .readdata(ReadDataM)
    );

    wire [31:0] ReadData0M =
        MemRead0M ? ReadDataM : 32'd0;

    wire [31:0] ReadData1M =
        (MemRead1M && select_mem1) ?
        ReadDataM : 32'd0;

    localparam MEMWB_WIDTH = 104;

    wire [MEMWB_WIDTH-1:0] data0M_memwb;
    wire [MEMWB_WIDTH-1:0] data1M_memwb;

    wire [MEMWB_WIDTH-1:0] data0W;
    wire [MEMWB_WIDTH-1:0] data1W;

    assign data0M_memwb = {
        pc0M,
        ALUResult0M,
        ReadData0M,
        rd_0M,
        ResultSrc0M,
        RegWrite0M
    };

    assign data1M_memwb = {
        pc1M,
        ALUResult1M,
        ReadData1M,
        rd_1M,
        ResultSrc1M,
        RegWrite1M
    };

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

    wire [31:0] pc0W;
    wire [31:0] ALUResult0W;
    wire [31:0] ReadData0W;
    wire [1:0] ResultSrc0W;

    assign {
        pc0W,
        ALUResult0W,
        ReadData0W,
        rd_0W,
        ResultSrc0W,
        RegWrite0W
    } = data0W;

    wire [31:0] pc1W;
    wire [31:0] ALUResult1W;
    wire [31:0] ReadData1W;
    wire [1:0] ResultSrc1W;

    assign {
        pc1W,
        ALUResult1W,
        ReadData1W,
        rd_1W,
        ResultSrc1W,
        RegWrite1W
    } = data1W;

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

    assign RegWriteEnable0W = valid0W && RegWrite0W;
    assign RegWriteEnable1W = valid1W && RegWrite1W;
endmodule
