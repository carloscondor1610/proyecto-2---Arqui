module idex (
    input clk, reset,
    input enable, flush,

    input [31:0] PCD, RD1D, RD2D, ImmExtD,
    input [4:0] Rs1D, Rs2D, RdD,

    input RegWriteD, MemWriteD, ALUSrcD,
    input BranchD, JumpD,
    input [1:0] ResultSrcD,
    input [3:0] ALUControlD,

    output reg [31:0] PCE, RD1E, RD2E, ImmExtE,
    output reg [4:0] Rs1E, Rs2E, RdE,

    output reg RegWriteE, MemWriteE, ALUSrcE,
    output reg BranchE, JumpE,
    output reg [1:0] ResultSrcE,
    output reg [3:0] ALUControlE
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            PCE <= 0;
            RD1E <= 0;
            RD2E <= 0;
            ImmExtE <= 0;

            Rs1E <= 0;
            Rs2E <= 0;
            RdE <= 0;

            RegWriteE <= 0;
            MemWriteE <= 0;
            ALUSrcE <= 0;
            BranchE <= 0;
            JumpE <= 0;

            ResultSrcE <= 0;
            ALUControlE <= 0;
        end
        else if (enable) begin
            PCE <= PCD;
            RD1E <= RD1D;
            RD2E <= RD2D;
            ImmExtE <= ImmExtD;

            Rs1E <= Rs1D;
            Rs2E <= Rs2D;
            RdE <= RdD;

            RegWriteE <= RegWriteD;
            MemWriteE <= MemWriteD;
            ALUSrcE <= ALUSrcD;
            BranchE <= BranchD;
            JumpE <= JumpD;

            ResultSrcE <= ResultSrcD;
            ALUControlE <= ALUControlD;
        end
    end

endmodule
