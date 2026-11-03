module testbench;

    reg clk, reset;
    wire [31:0] WriteData, DataAdr;
    wire MemWrite;
    integer errors;

    top dut (
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check_reg;
        input [4:0] regnum;
        input [31:0] expected;
        begin
            if (dut.rvsingle.rf.rf[regnum] !== expected) begin
                $display("FAIL x%0d: esperado=%h obtenido=%h",
                    regnum, expected, dut.rvsingle.rf.rf[regnum]);
                errors = errors + 1;
            end else begin
                $display("PASS x%0d = %h", regnum, expected);
            end
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, testbench);
        errors = 0;
        reset = 1;
        #22;
        reset = 0;
        repeat (60) @(negedge clk);
        #1;

        $display("=== REGRESION PIPELINE ===");

        check_reg(1, 32'd100);
        check_reg(2, 32'd42);
        check_reg(3, 32'hfffffff8);
        check_reg(4, 32'd3);
        check_reg(7, 32'd45);
        check_reg(8, 32'd39);
        check_reg(9, 32'd2);
        check_reg(10, 32'd43);
        check_reg(11, 32'd41);
        check_reg(12, 32'd24);
        check_reg(13, 32'd5);
        check_reg(14, 32'hffffffff);
        check_reg(15, 32'd1);
        check_reg(16, 32'd0);
        check_reg(17, 32'd37);
        check_reg(18, 32'hfffffffe);
        check_reg(19, 32'd1);
        check_reg(20, 32'd42);
        check_reg(21, 32'd50);
        check_reg(22, 32'd1);
        check_reg(23, 32'd1);
        check_reg(24, 32'd77);
        check_reg(25, 32'd176);
        check_reg(26, 32'd88);
        check_reg(27, 32'd12);
        check_reg(28, 32'd21);
        check_reg(29, 32'd1);
        check_reg(30, 32'd0);
        check_reg(31, 32'd10);

        if (dut.dmem.RAM[25] !== 32'd42) begin
            $display("FAIL MEM[100]: esperado=42 obtenido=%h",
                dut.dmem.RAM[25]);
            errors = errors + 1;
        end else begin
            $display("PASS MEM[100] = 42");
        end

        if (errors == 0)
            $display("REGRESSION TEST PASSED");
        else
            $display("REGRESSION TEST FAILED: %0d errores", errors);

        $finish;
    end

endmodule
