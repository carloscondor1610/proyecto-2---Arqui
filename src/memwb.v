module memwb (
    input clk, reset,
    input enable, flush,

    // Datos provenientes de Memory
    input [31:0] ALUResultM,
  input [31:0] ReadDataM,
    input [31:0] PCPlus4M,
    input [4:0] RdM,

    // Señales de control
    input RegWriteM,
    input [1:0] ResultSrcM,

    // Datos enviados a Write Back
    output reg [31:0] ALUResultW,
    output reg [31:0] ReadDataW,
    output reg [31:0] PCPlus4W,
    output reg [4:0] RdW,

    // Control enviado a Write Back
    output reg RegWriteW,
    output reg [1:0] ResultSrcW
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin

            ALUResultW <= 0;
            ReadDataW  <= 0;
            PCPlus4W   <= 0;
            RdW        <= 0;

            RegWriteW  <= 0;
            ResultSrcW <= 0;

        end
        else if (enable) begin

            ALUResultW <= ALUResultM;
            ReadDataW  <= ReadDataM;
            PCPlus4W   <= PCPlus4M;
            RdW        <= RdM;

            RegWriteW  <= RegWriteM;
            ResultSrcW <= ResultSrcM;

        end
    end

endmodule
