module ifid (
    input clk, reset,
    input enable, flush,
    input [31:0] PCF, InstrF,
    output reg [31:0] PCD, InstrD
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PCD    <= 32'b0;
            InstrD <= 32'h00000013;
        end
        else if (flush) begin
            PCD    <= 32'b0;
            InstrD <= 32'h00000013;
        end
        else if (enable) begin
            PCD    <= PCF;
            InstrD <= InstrF;
        end
    end

endmodule
