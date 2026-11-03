module aludec(
    input opb5,
    input [2:0] funct3,
    input funct7b5,
    input [1:0] ALUOp,
    output reg [3:0] ALUControl
);

    wire RtypeSub;

    assign RtypeSub = opb5 & funct7b5;

    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = 4'b0000;

            2'b01: ALUControl = 4'b0001;

            2'b10: begin
                case (funct3)
                    3'b000: ALUControl = RtypeSub ? 4'b0001 : 4'b0000;
                    3'b001: ALUControl = 4'b0110;
                    3'b010: ALUControl = 4'b0101;
                    3'b011: ALUControl = 4'b1001;
                    3'b100: ALUControl = 4'b1000;
                    3'b101: ALUControl = funct7b5 ? 4'b1010 : 4'b0111;
                    3'b110: ALUControl = 4'b0011;
                    3'b111: ALUControl = 4'b0010;
                    default: ALUControl = 4'bxxxx;
                endcase
            end

            default: ALUControl = 4'bxxxx;
        endcase
    end

endmodule
