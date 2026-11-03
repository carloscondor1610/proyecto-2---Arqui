`timescale 1ns / 1ps

module hazard_unit (
    input [4:0] Rs1D, Rs2D,
    input UsesRs1D, UsesRs2D,

    input [4:0] RdE,
    input RegWriteE,
    input [1:0] ResultSrcE,

    input PCSrcE,

    output StallF, StallD,
    output FlushD, FlushE
);

    wire LoadUseHazard;

    assign LoadUseHazard =
        RegWriteE &&
        (ResultSrcE == 2'b01) &&
        (RdE != 5'd0) &&
        (
            (UsesRs1D && (Rs1D == RdE)) ||
            (UsesRs2D && (Rs2D == RdE))
        );

    assign StallF = LoadUseHazard && !PCSrcE;
    assign StallD = LoadUseHazard && !PCSrcE;

    assign FlushD = PCSrcE;
    assign FlushE = PCSrcE || LoadUseHazard;

endmodule