`timescale 1ns/1ps

module tb_integrante2;
    integer passed = 0;
    integer failed = 0;

    logic [4:0] Rs1D, Rs2D, RdD0, Rs1D1, Rs2D1;
    logic UsesRs1D, UsesRs2D, RegWriteD0, ValidD0;
    logic UsesRs1D1, UsesRs2D1, ValidD1;
    logic [4:0] RdE, RdE1;
    logic RegWriteE, RegWriteE1, ValidE0, ValidE1;
    logic [1:0] ResultSrcE, ResultSrcE1;
    logic PCSrcE;
    wire StallF, StallD, FlushD, FlushE;
    wire RAWPair, LoadUseHazard0, LoadUseHazard1;
    wire BlockIssue0, BlockIssue1, StallBoth, IssueOnly0;

    hazard_unit hz (
        .Rs1D(Rs1D), .Rs2D(Rs2D), .RdD0(RdD0),
        .UsesRs1D(UsesRs1D), .UsesRs2D(UsesRs2D),
        .RegWriteD0(RegWriteD0), .ValidD0(ValidD0),
        .Rs1D1(Rs1D1), .Rs2D1(Rs2D1),
        .UsesRs1D1(UsesRs1D1), .UsesRs2D1(UsesRs2D1), .ValidD1(ValidD1),
        .RdE(RdE), .RegWriteE(RegWriteE), .ResultSrcE(ResultSrcE), .ValidE0(ValidE0),
        .RdE1(RdE1), .RegWriteE1(RegWriteE1), .ResultSrcE1(ResultSrcE1), .ValidE1(ValidE1),
        .PCSrcE(PCSrcE),
        .StallF(StallF), .StallD(StallD), .FlushD(FlushD), .FlushE(FlushE),
        .RAWPair(RAWPair), .LoadUseHazard0(LoadUseHazard0),
        .LoadUseHazard1(LoadUseHazard1), .BlockIssue0(BlockIssue0),
        .BlockIssue1(BlockIssue1), .StallBoth(StallBoth), .IssueOnly0(IssueOnly0)
    );

    logic [4:0] Rs1E, Rs2E, Rs1E1, Rs2E1, RdM, RdM1, RdW, RdW1;
    logic UsesRs1E0, UsesRs2E0, UsesRs1E1, UsesRs2E1;
    logic RegWriteM, RegWriteM1, RegWriteW, RegWriteW1;
    logic ValidM0, ValidM1, ValidW0, ValidW1;
    logic [1:0] ResultSrcM, ResultSrcM1;
    wire [2:0] ForwardAE, ForwardBE, ForwardAE1, ForwardBE1;
    wire ForwardStall0, ForwardStall1;

    forwarding_unit fw (
        .Rs1E(Rs1E), .Rs2E(Rs2E), .Rs1E1(Rs1E1), .Rs2E1(Rs2E1),
        .UsesRs1E0(UsesRs1E0), .UsesRs2E0(UsesRs2E0),
        .UsesRs1E1(UsesRs1E1), .UsesRs2E1(UsesRs2E1),
        .RdM(RdM), .RdM1(RdM1), .RdW(RdW), .RdW1(RdW1),
        .RegWriteM(RegWriteM), .RegWriteM1(RegWriteM1),
        .RegWriteW(RegWriteW), .RegWriteW1(RegWriteW1),
        .ValidM0(ValidM0), .ValidM1(ValidM1), .ValidW0(ValidW0), .ValidW1(ValidW1),
        .ResultSrcM(ResultSrcM), .ResultSrcM1(ResultSrcM1),
        .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
        .ForwardAE1(ForwardAE1), .ForwardBE1(ForwardBE1),
        .ForwardStall0(ForwardStall0), .ForwardStall1(ForwardStall1)
    );

    logic valid0E, valid1E, Branch0E, Branch1E, Jump0E, Jump1E;
    logic [2:0] funct3_0E, funct3_1E;
    logic [31:0] SrcA0, SrcA1, RegB0, RegB1, pc0E, pc1E, immext0E, immext1E;
    wire redirectE, kill_lane1E, branch_conflictE;
    wire [31:0] redirect_pcE;

    branch_control_dual br (
        .valid0E(valid0E), .valid1E(valid1E),
        .Branch0E(Branch0E), .Branch1E(Branch1E),
        .Jump0E(Jump0E), .Jump1E(Jump1E),
        .UsesRs1E0(UsesRs1E0), .UsesRs1E1(UsesRs1E1),
        .funct3_0E(funct3_0E), .funct3_1E(funct3_1E),
        .SrcA0(SrcA0), .SrcA1(SrcA1), .RegB0(RegB0), .RegB1(RegB1),
        .pc0E(pc0E), .pc1E(pc1E), .immext0E(immext0E), .immext1E(immext1E),
        .redirectE(redirectE), .redirect_pcE(redirect_pcE),
        .kill_lane1E(kill_lane1E), .branch_conflictE(branch_conflictE)
    );

    logic MemConflict, BranchConflict, Redirect;
    wire Issue0, Issue1, HoldDecode, PartialIssue;
    wire [1:0] IssueCount;

    hazard_issue_control ic (
        .ValidD0(ValidD0), .ValidD1(ValidD1),
        .BlockIssue0(BlockIssue0), .BlockIssue1(BlockIssue1),
        .MemConflict(MemConflict), .BranchConflict(BranchConflict), .Redirect(Redirect),
        .Issue0(Issue0), .Issue1(Issue1),
        .HoldDecode(HoldDecode), .PartialIssue(PartialIssue), .IssueCount(IssueCount)
    );

    task automatic clear_all;
    begin
        Rs1D=0; Rs2D=0; RdD0=0; Rs1D1=0; Rs2D1=0;
        UsesRs1D=0; UsesRs2D=0; RegWriteD0=0; ValidD0=1;
        UsesRs1D1=0; UsesRs2D1=0; ValidD1=1;
        RdE=0; RdE1=0; RegWriteE=0; RegWriteE1=0;
        ValidE0=0; ValidE1=0; ResultSrcE=0; ResultSrcE1=0; PCSrcE=0;
        Rs1E=0; Rs2E=0; Rs1E1=0; Rs2E1=0;
        UsesRs1E0=0; UsesRs2E0=0; UsesRs1E1=0; UsesRs2E1=0;
        RdM=0; RdM1=0; RdW=0; RdW1=0;
        RegWriteM=0; RegWriteM1=0; RegWriteW=0; RegWriteW1=0;
        ValidM0=0; ValidM1=0; ValidW0=0; ValidW1=0;
        ResultSrcM=0; ResultSrcM1=0;
        valid0E=0; valid1E=0; Branch0E=0; Branch1E=0;
        Jump0E=0; Jump1E=0; funct3_0E=0; funct3_1E=0;
        SrcA0=0; SrcA1=0; RegB0=0; RegB1=0;
        pc0E=32'h100; pc1E=32'h104; immext0E=16; immext1E=20;
        MemConflict=0; BranchConflict=0; Redirect=0;
    end
    endtask

`define CHECK(NAME, EXPR) \
    begin \
        #1; \
        if ((EXPR) === 1'b1) begin \
            passed=passed+1; $display("PASS %0d: %s", passed+failed, NAME); \
        end else begin \
            failed=failed+1; $display("FAIL %0d: %s", passed+failed, NAME); \
        end \
    end

    initial begin
        $display("===== INTEGRANTE 2: PRUEBAS CONJUNTAS =====");
        clear_all();
        `CHECK("RAW: ninguna dependencia", !RAWPair && !LoadUseHazard0 && !LoadUseHazard1)
        clear_all(); RdD0=5; RegWriteD0=1; Rs1D1=5; UsesRs1D1=1;
        `CHECK("RAW entre candidatas", RAWPair && BlockIssue1 && !BlockIssue0 && IssueOnly0)
        clear_all(); RdD0=5; RegWriteD0=1; Rs1D1=5; UsesRs1D1=0;
        `CHECK("RAW: fuente no utilizada", !RAWPair)
        clear_all(); RdD0=0; RegWriteD0=1; Rs1D1=0; UsesRs1D1=1;
        `CHECK("RAW: x0 ignorado", !RAWPair)
        clear_all(); RdE=7; ValidE0=1; RegWriteE=1; ResultSrcE=1; Rs1D=7; UsesRs1D=1;
        `CHECK("Load-use: EX0 bloquea lane0", LoadUseHazard0 && StallBoth && StallF && StallD && FlushE && !Issue0)
        clear_all(); RdE1=8; ValidE1=1; RegWriteE1=1; ResultSrcE1=1; Rs2D1=8; UsesRs2D1=1;
        `CHECK("Load-use: EX1 bloquea lane1", LoadUseHazard1 && !LoadUseHazard0 && IssueOnly0 && Issue0 && !Issue1)
        clear_all(); RdE=9; ValidE0=1; RegWriteE=1; ResultSrcE=0; Rs1D=9; UsesRs1D=1;
        `CHECK("Dependencia ALU no provoca load stall", !LoadUseHazard0)
        clear_all(); RdE=6; ValidE0=1; RegWriteE=1; ResultSrcE=1; Rs1D=6; UsesRs1D=1; PCSrcE=1;
        `CHECK("Branch redirige y flush tiene prioridad", FlushD && FlushE && !StallF)

        clear_all();
        `CHECK("Issue: dos candidatas independientes", IssueCount==2 && Issue0 && Issue1)
        clear_all(); ValidD1=0;
        `CHECK("Issue: una candidata", IssueCount==1 && Issue0 && !Issue1)
        clear_all(); MemConflict=1;
        `CHECK("Issue: conflicto memoria", IssueOnly0==0 && PartialIssue && IssueCount==1)
        clear_all(); BranchConflict=1;
        `CHECK("Issue: conflicto branch", PartialIssue && IssueCount==1)
        clear_all(); ValidD0=0; ValidD1=0;
        `CHECK("Issue: cero instrucciones validas", IssueCount==0)
        clear_all(); Redirect=1;
        `CHECK("Issue: redireccion inhibe emision", IssueCount==0)

        clear_all();
        `CHECK("Forward: sin coincidencias", ForwardAE==0 && ForwardBE==0 && ForwardAE1==0 && ForwardBE1==0)
        clear_all(); Rs1E=5; UsesRs1E0=1; RdM=5; ValidM0=1; RegWriteM=1;
        `CHECK("Forward: MEM0 -> EX0 A", ForwardAE==3'd1 && !ForwardStall0)
        clear_all(); Rs2E=6; UsesRs2E0=1; RdM1=6; ValidM1=1; RegWriteM1=1;
        `CHECK("Forward: MEM1 -> EX0 B", ForwardBE==3'd2 && !ForwardStall0)
        clear_all(); Rs1E1=7; UsesRs1E1=1; RdW=7; ValidW0=1; RegWriteW=1;
        `CHECK("Forward: WB0 -> EX1 A", ForwardAE1==3'd3)
        clear_all(); Rs2E1=8; UsesRs2E1=1; RdW1=8; ValidW1=1; RegWriteW1=1;
        `CHECK("Forward: WB1 -> EX1 B", ForwardBE1==3'd4)
        clear_all(); Rs1E=9; UsesRs1E0=1; RdM=9; RdW=9; ValidM0=1; ValidW0=1; RegWriteM=1; RegWriteW=1;
        `CHECK("Forward: MEM tiene prioridad a WB", ForwardAE==3'd1)
        clear_all(); Rs1E=10; UsesRs1E0=1; RdM=10; RdM1=10; ValidM0=1; ValidM1=1; RegWriteM=1; RegWriteM1=1;
        `CHECK("Forward: lane1 M es mas joven", ForwardAE==3'd2)
        clear_all(); Rs1E=11; UsesRs1E0=1; RdM=11; ValidM0=1; RegWriteM=1; ResultSrcM=1;
        `CHECK("Forward: load MEM0 requiere espera", ForwardStall0 && ForwardAE==0)
        clear_all(); Rs1E1=12; UsesRs1E1=1; RdM1=12; ValidM1=1; RegWriteM1=1; ResultSrcM1=1;
        `CHECK("Forward: load MEM1 requiere espera", ForwardStall1 && ForwardAE1==0)
        clear_all(); Rs1E=0; UsesRs1E0=1; RdM=0; ValidM0=1; RegWriteM=1;
        `CHECK("Forward: x0 ignorado", ForwardAE==0)
        clear_all(); Rs1E=4; UsesRs1E0=0; RdM=4; ValidM0=1; RegWriteM=1;
        `CHECK("Forward: fuente no utilizada", ForwardAE==0)

        clear_all(); valid0E=1; Branch0E=1; funct3_0E=0; SrcA0=6; RegB0=6;
        `CHECK("Branch: BEQ tomado lane0", redirectE && redirect_pcE==32'h110 && kill_lane1E)
        clear_all(); valid0E=1; Branch0E=1; funct3_0E=0; SrcA0=6; RegB0=7;
        `CHECK("Branch: BEQ no tomado", !redirectE && !kill_lane1E)
        clear_all(); valid1E=1; Branch1E=1; funct3_1E=1; SrcA1=3; RegB1=4;
        `CHECK("Branch: BNE tomado lane1", redirectE && redirect_pcE==32'h118 && !kill_lane1E)
        clear_all(); valid0E=1; Branch0E=1; funct3_0E=3'b100; SrcA0=32'hffffffff; RegB0=1;
        `CHECK("Branch: BLT signed", redirectE && redirect_pcE==32'h110)
        clear_all(); valid0E=1; Branch0E=1; funct3_0E=3'b110; SrcA0=32'hffffffff; RegB0=1;
        `CHECK("Branch: BLTU unsigned no tomado", !redirectE)
        clear_all(); valid1E=1; Jump1E=1; UsesRs1E1=0;
        `CHECK("Branch: JAL lane1", redirectE && redirect_pcE==32'h118)
        clear_all(); valid0E=1; Jump0E=1; UsesRs1E0=1; SrcA0=32'h123; immext0E=4;
        `CHECK("Branch: JALR limpia bit cero", redirectE && redirect_pcE==32'h126)
        clear_all(); valid0E=1; valid1E=1; Branch0E=1; Branch1E=1;
        `CHECK("Branch: conflicto de dos branches detectado", branch_conflictE)

        $display("=========================================");
        $display("INTEGRANTE 2: %0d PASS / %0d FAIL", passed, failed);
        $display("=========================================");
        if (failed != 0) $fatal(1, "HAY FUNCIONES QUE CORREGIR");
        else $display("TESTS DE MODULOS INTEGRANTE 2 PASSED");
        $finish;
    end
endmodule
