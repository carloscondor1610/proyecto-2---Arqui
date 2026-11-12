`timescale 1ns / 1ps

module branch_control_dual (
    input wire valid0E,
    input wire valid1E,
    input wire Branch0E,
    input wire Branch1E,
    input wire Jump0E,
    input wire Jump1E,
    input wire UsesRs1E0,
    input wire UsesRs1E1,
    input wire [2:0] funct3_0E,
    input wire [2:0] funct3_1E,
    input wire [31:0] SrcA0,
    input wire [31:0] SrcA1,
    input wire [31:0] RegB0,
    input wire [31:0] RegB1,
    input wire [31:0] pc0E,
    input wire [31:0] pc1E,
    input wire [31:0] immext0E,
    input wire [31:0] immext1E,
    output wire redirectE,
    output wire [31:0] redirect_pcE,
    output wire kill_lane1E,
    output wire branch_conflictE
);
    function automatic branch_condition;
        input [2:0] funct3;
        input [31:0] a;
        input [31:0] b;
        begin
            case (funct3)
                3'b000: branch_condition = (a == b);
                3'b001: branch_condition = (a != b);
                3'b100: branch_condition = ($signed(a) < $signed(b));
                3'b101: branch_condition = ($signed(a) >= $signed(b));
                3'b110: branch_condition = (a < b);
                3'b111: branch_condition = (a >= b);
                default: branch_condition = 1'b0;
            endcase
        end
    endfunction

    wire ctrl0 = valid0E && (Branch0E || Jump0E);
    wire ctrl1 = valid1E && (Branch1E || Jump1E);
    assign branch_conflictE = ctrl0 && ctrl1;

    wire take0 = valid0E &&
        (Jump0E || (Branch0E && branch_condition(funct3_0E, SrcA0, RegB0)));
    wire take1 = !ctrl0 && valid1E &&
        (Jump1E || (Branch1E && branch_condition(funct3_1E, SrcA1, RegB1)));

    wire [31:0] target0 =
        (Jump0E && UsesRs1E0) ? ((SrcA0 + immext0E) & 32'hfffffffe) :
        (pc0E + immext0E);
    wire [31:0] target1 =
        (Jump1E && UsesRs1E1) ? ((SrcA1 + immext1E) & 32'hfffffffe) :
        (pc1E + immext1E);

    assign redirectE = take0 || take1;
    assign redirect_pcE = take0 ? target0 : target1;
    assign kill_lane1E = take0;
endmodule
