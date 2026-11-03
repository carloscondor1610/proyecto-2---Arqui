`timescale 1ns / 1ps
module forwarding_unit (
    input [4:0] Rs1E, Rs2E,
    input [4:0] RdM, RdW,
    input RegWriteM, RegWriteW,
    input [1:0] ResultSrcM,

    output reg [1:0] ForwardAE, ForwardBE
);


    always @(*) begin
        ForwardAE = 2'b00;
        ForwardBE = 2'b00;
        if (RegWriteM && (RdM != 5'd0) && (RdM == Rs1E)) begin
            if (ResultSrcM != 2'b01)
                ForwardAE = 2'b10;
        end
        else if (RegWriteW && (RdW != 5'd0) && (RdW == Rs1E))
            ForwardAE = 2'b01;

        if (RegWriteM && (RdM != 5'd0) && (RdM == Rs2E)) begin
            if (ResultSrcM != 2'b01)
                ForwardBE = 2'b10;
        end
        else if (RegWriteW && (RdW != 5'd0) && (RdW == Rs2E))
            ForwardBE = 2'b01;
    end

endmodule