`timescale 1ns / 1ps

module tb_issue_unit;
    logic valid0, valid1, block0, block1;
    logic mem_conflict, branch_conflict, flush, hold_request;
    wire issue0, issue1, hold_decode, partial_issue;
    wire [1:0] issue_count, fetch_count;

    issue_unit dut (
        .ValidD0(valid0), .ValidD1(valid1),
        .BlockIssue0(block0), .BlockIssue1(block1),
        .MemConflict(mem_conflict), .BranchConflict(branch_conflict),
        .Flush(flush), .HoldRequest(hold_request),
        .Issue0(issue0), .Issue1(issue1),
        .HoldDecode(hold_decode), .PartialIssue(partial_issue),
        .IssueCount(issue_count), .FetchCount(fetch_count)
    );

    task automatic check_issue(
        input string name,
        input logic [1:0] expected_lanes,
        input logic [1:0] expected_issue,
        input logic [1:0] expected_fetch,
        input logic expected_hold,
        input logic expected_partial
    );
        #1;
        if ({issue1, issue0} !== expected_lanes ||
            issue_count !== expected_issue || fetch_count !== expected_fetch ||
            hold_decode !== expected_hold || partial_issue !== expected_partial)
            $fatal(1, "%s lanes=%b issue=%0d fetch=%0d hold=%b partial=%b",
                   name, {issue1, issue0}, issue_count, fetch_count, hold_decode, partial_issue);
        $display("PASS: %s", name);
    endtask

    initial begin
        {valid0, valid1, block0, block1, mem_conflict, branch_conflict, flush, hold_request} = '0;
        check_issue("ventana vacia se llena", 2'b00, 0, 2, 0, 0);

        valid0 = 1;
        check_issue("una candidata valida", 2'b01, 1, 2, 0, 0);
        valid1 = 1;
        check_issue("dos candidatas independientes", 2'b11, 2, 2, 0, 0);

        block0 = 1;
        check_issue("hazard de la mas antigua bloquea ambas", 2'b00, 0, 0, 1, 0);
        block0 = 0;
        block1 = 1;
        check_issue("hazard de la joven permite emision parcial", 2'b01, 1, 1, 0, 1);
        block1 = 0;
        mem_conflict = 1;
        check_issue("conflicto de memoria", 2'b01, 1, 1, 0, 1);
        mem_conflict = 0;
        branch_conflict = 1;
        check_issue("conflicto de saltos", 2'b01, 1, 1, 0, 1);
        branch_conflict = 0;

        hold_request = 1;
        check_issue("pausa externa", 2'b00, 0, 0, 1, 0);
        flush = 1;
        check_issue("flush tiene prioridad sobre pausa", 2'b00, 0, 0, 0, 0);
        $display("ISSUE UNIT TEST PASSED");
        $finish;
    end
endmodule
