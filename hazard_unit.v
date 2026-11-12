`timescale 1ns / 1ps
module hazard_unit (
    input wire [4:0] Rs1D, Rs2D, RdD0,
    input wire UsesRs1D, UsesRs2D, RegWriteD0, ValidD0,
    input wire [4:0] Rs1D1, Rs2D1,
    input wire UsesRs1D1, UsesRs2D1, ValidD1,
    input wire [4:0] RdE,
    input wire RegWriteE,
    input wire [1:0] ResultSrcE,
    input wire ValidE0,
    input wire [4:0] RdE1,
    input wire RegWriteE1,
    input wire [1:0] ResultSrcE1,
    input wire ValidE1,
    input wire PCSrcE,
    output wire StallF, StallD, FlushD, FlushE,
    output wire RAWPair, LoadUseHazard0, LoadUseHazard1,
    output wire BlockIssue0, BlockIssue1, StallBoth, IssueOnly0
);
    wire load0 = ValidE0 && RegWriteE && (ResultSrcE == 2'b01) && (RdE != 5'd0);
    wire load1 = ValidE1 && RegWriteE1 && (ResultSrcE1 == 2'b01) && (RdE1 != 5'd0);
    wire match0_0 = (UsesRs1D && Rs1D == RdE) || (UsesRs2D && Rs2D == RdE);
    wire match0_1 = (UsesRs1D && Rs1D == RdE1) || (UsesRs2D && Rs2D == RdE1);
    wire match1_0 = (UsesRs1D1 && Rs1D1 == RdE) || (UsesRs2D1 && Rs2D1 == RdE);
    wire match1_1 = (UsesRs1D1 && Rs1D1 == RdE1) || (UsesRs2D1 && Rs2D1 == RdE1);
    assign LoadUseHazard0 = ValidD0 && ((load0 && match0_0) || (load1 && match0_1));
    assign LoadUseHazard1 = ValidD1 && ((load0 && match1_0) || (load1 && match1_1));
    assign RAWPair = ValidD0 && ValidD1 && RegWriteD0 && (RdD0 != 5'd0) &&
                     ((UsesRs1D1 && Rs1D1 == RdD0) || (UsesRs2D1 && Rs2D1 == RdD0));
    assign BlockIssue0 = LoadUseHazard0;
    assign BlockIssue1 = LoadUseHazard1 || RAWPair;
    assign StallBoth = BlockIssue0;
    assign IssueOnly0 = !BlockIssue0 && BlockIssue1;
    assign StallF = StallBoth && !PCSrcE;
    assign StallD = StallBoth && !PCSrcE;
    assign FlushD = PCSrcE;
    assign FlushE = PCSrcE || StallBoth;
endmodule
