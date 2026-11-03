module alu(
    input [31:0] a, b,
    input [3:0] alucontrol,
    output reg [31:0] result,
    output zero
);

    always @(*) begin
        case (alucontrol)
            4'b0000: result = a + b;
            4'b0001: result = a - b;
            4'b0010: result = a & b;
            4'b0011: result = a | b;
            4'b0100: result = 32'b0;
            4'b0101: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            4'b0110: result = a << b[4:0];
            4'b0111: result = a >> b[4:0];
            4'b1000: result = a ^ b;
            4'b1001: result = (a < b) ? 32'd1 : 32'd0;
            4'b1010: result = $signed(a) >>> b[4:0];
            default: result = 32'hxxxxxxxx;
        endcase
    end

    assign zero = (result == 32'b0);

endmodule
