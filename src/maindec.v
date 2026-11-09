`timescale 1ns / 1ps

module maindec(
    input [6:0] op,
    input [2:0] funct3,

    output [1:0] ResultSrc,
    output MemWrite,
    output Branch,
    output ALUSrc,
    output RegWrite,
    output Jump,
    output [1:0] ImmSrc,
    output [1:0] ALUOp
);

    reg [10:0] controls;

    assign {
        RegWrite,
        ImmSrc,
        ALUSrc,
        MemWrite,
        ResultSrc,
        Branch,
        ALUOp,
        Jump
    } = controls;

    always @(*) begin

        // Valores por defecto
        controls = 11'b0_00_0_0_00_0_00_0;

        case (op)

            // ==================================
            // LOAD: LB, LH, LW, LBU, LHU
            // ==================================
            7'b0000011: begin
                case (funct3)
                    3'b000, // LB
                    3'b001, // LH
                    3'b010, // LW
                    3'b100, // LBU
                    3'b101: // LHU
                        controls = 11'b1_00_1_0_01_0_00_0;

                    default:
                        controls = 11'b0_00_0_0_00_0_00_0;
                endcase
            end

            // ==================================
            // STORE: SB, SH, SW
            // ==================================
            7'b0100011: begin
                case (funct3)
                    3'b000, // SB
                    3'b001, // SH
                    3'b010: // SW
                        controls = 11'b0_01_1_1_00_0_00_0;

                    default:
                        controls = 11'b0_00_0_0_00_0_00_0;
                endcase
            end

            // ==================================
            // R-TYPE
            // ==================================
            7'b0110011: begin
                controls = 11'b1_00_0_0_00_0_10_0;
            end

            // ==================================
            // BRANCH: BEQ
            // ==================================
            7'b1100011: begin
                if (funct3 == 3'b000)
                    controls = 11'b0_10_0_0_00_1_01_0;
            end

            // ==================================
            // I-TYPE ALU
            // ==================================
            7'b0010011: begin
                controls = 11'b1_00_1_0_00_0_10_0;
            end

            // ==================================
            // JAL
            // ==================================
            7'b1101111: begin
                controls = 11'b1_11_0_0_10_0_00_1;
            end

            default: begin
                controls = 11'b0_00_0_0_00_0_00_0;
            end

        endcase
    end

endmodule