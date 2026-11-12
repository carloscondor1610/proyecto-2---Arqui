`timescale 1ns / 1ps
module hazard_issue_control (
    input wire ValidD0, ValidD1,
    input wire BlockIssue0, BlockIssue1,
    input wire MemConflict, BranchConflict, Redirect,
    output wire Issue0, Issue1, HoldDecode, PartialIssue,
    output wire [1:0] IssueCount
);
    assign Issue0=ValidD0 && !BlockIssue0 && !Redirect;
    assign Issue1=Issue0 && ValidD1 && !BlockIssue1 && !MemConflict && !BranchConflict;
    assign IssueCount={1'b0,Issue0}+{1'b0,Issue1};
    assign PartialIssue=Issue0 && ValidD1 && !Issue1;
    assign HoldDecode=ValidD0 && !Issue0;
endmodule
