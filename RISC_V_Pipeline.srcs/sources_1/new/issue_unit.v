`timescale 1ns / 1ps

module issue_unit (
    input wire ValidD0, ValidD1,
    input wire BlockIssue0, BlockIssue1,
    input wire MemConflict, BranchConflict,
    input wire Flush, HoldRequest,

    output wire Issue0, Issue1,
    output wire HoldDecode, PartialIssue,
    output wire [1:0] IssueCount, FetchCount
);
    wire blocked_window;

    hazard_issue_control select_issue (
        .ValidD0(ValidD0),
        .ValidD1(ValidD1),
        .BlockIssue0(BlockIssue0),
        .BlockIssue1(BlockIssue1),
        .MemConflict(MemConflict),
        .BranchConflict(BranchConflict),
        .Redirect(Flush | HoldRequest),
        .Issue0(Issue0),
        .Issue1(Issue1),
        .HoldDecode(blocked_window),
        .PartialIssue(PartialIssue),
        .IssueCount(IssueCount)
    );

    assign HoldDecode = !Flush && (HoldRequest || blocked_window);

    // Una ventana vacia tambien admite dos instrucciones. En emision
    // parcial se rellena solo la ranura que libera la instruccion antigua.
    assign FetchCount = (Flush || HoldDecode) ? 2'd0 :
                        PartialIssue ? 2'd1 : 2'd2;
endmodule
