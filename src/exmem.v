module exmem (
    input clk, reset,
    input enable, flush,

    // Datos provenientes de Execute
    input [31:0] ALUResultE, RD2E, PCPlus4E,
    input [4:0] RdE,

    // Señales de control
    input RegWriteE, MemWriteE,
    input [1:0] ResultSrcE,

    // Datos enviados a Memory
    output reg [31:0] ALUResultM,
    output reg [31:0] WriteDataM,
    output reg [31:0] PCPlus4M,
    output reg [4:0] RdM,

    // Control enviado a Memory
    output reg RegWriteM, MemWriteM,
    output reg [1:0] ResultSrcM
);

    always @(posedge clk or posedge reset) begin

        if (reset || flush) begin

            ALUResultM <= 0;
            WriteDataM <= 0;
            PCPlus4M   <= 0;
            RdM        <= 0;

            RegWriteM  <= 0;
            MemWriteM  <= 0;
            ResultSrcM <= 0;

        end
        else if (enable) begin

            ALUResultM <= ALUResultE;
            WriteDataM <= RD2E;
            PCPlus4M   <= PCPlus4E;
            RdM        <= RdE;

            RegWriteM  <= RegWriteE;
            MemWriteM  <= MemWriteE;
            ResultSrcM <= ResultSrcE;

        end
    end

endmodule
