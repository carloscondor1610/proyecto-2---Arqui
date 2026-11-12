`timescale 1ns / 1ps
module idex_dual #(parameter WIDTH=159)(
    input wire clk, reset, enable, flush,
    input wire issue0D, issue1D, flush0, flush1,
    input wire valid0D, valid1D,
    input wire [WIDTH-1:0] data0D, data1D,
    output reg valid0E, valid1E,
    output reg [WIDTH-1:0] data0E, data1E
);
    always @(posedge clk or posedge reset) begin
        if(reset || flush) begin
            valid0E <= 1'b0; valid1E <= 1'b0;
            data0E <= {WIDTH{1'b0}}; data1E <= {WIDTH{1'b0}};
        end else if(enable) begin
            valid0E <= valid0D && issue0D && !flush0;
            valid1E <= valid1D && issue1D && !flush1;
            data0E <= (issue0D && !flush0) ? data0D : {WIDTH{1'b0}};
            data1E <= (issue1D && !flush1) ? data1D : {WIDTH{1'b0}};
        end
    end
endmodule
