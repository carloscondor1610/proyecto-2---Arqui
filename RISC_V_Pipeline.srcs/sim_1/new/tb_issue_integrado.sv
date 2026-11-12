`timescale 1ns / 1ps

module tb_issue_integrado;
    reg clk = 0;
    reg reset = 1;
    wire [31:0] pcF;
    wire valid0D, valid1D;

    localparam integer PROGRAM_END = 152;
    localparam integer EXPECTED_RETIRED = 32;
    integer retired = 0;
    integer stores_at_0 = 0;
    integer stores_at_4 = 0;

    always #5 clk = ~clk;

    datapath_dual dut (
        .clk(clk), .reset(reset),
        .advance(2'd0), .redirect(1'b0), .redirect_pc(32'd0),
        .stallD(1'b0), .flushD(1'b0),
        .we_test(1'b0), .wa_test(5'd0), .wd_test(32'd0),
        .pcF(pcF), .pc1F(), .instr0D(), .instr1D(),
        .valid0D(valid0D), .valid1D(valid1D),
        .result0(), .result1()
    );

    task automatic tick;
        @(posedge clk);
        #1;
    endtask

    task automatic expect_decode(
        input logic [31:0] oldest_pc, youngest_pc,
        input logic [1:0] expected_issue, expected_fetch
    );
        if ({valid1D, valid0D} !== 2'b11 ||
            dut.pc0D !== oldest_pc || dut.pc1D !== youngest_pc ||
            dut.IssueCount !== expected_issue || dut.FetchCount !== expected_fetch)
            $fatal(1, "D=(%0d,%0d) valid=%b%b issue=%0d fetch=%0d, esperado D=(%0d,%0d) issue=%0d fetch=%0d",
                   dut.pc0D, dut.pc1D, valid1D, valid0D, dut.IssueCount, dut.FetchCount,
                   oldest_pc, youngest_pc, expected_issue, expected_fetch);
    endtask

    task automatic check_retire(input logic [31:0] pc);
        logic [31:0] expected_pc;
        if (pc < PROGRAM_END) begin
            if (retired < 15)
                expected_pc = 4 * retired;
            else if (retired < 17)
                expected_pc = 68 + 4 * (retired - 15);
            else if (retired < 30)
                expected_pc = 84 + 4 * (retired - 17);
            else
                expected_pc = 144 + 4 * (retired - 30);

            if (retired >= EXPECTED_RETIRED || pc !== expected_pc)
                $fatal(1, "Retiro %0d: PC esperado %0d, obtenido %0d", retired, expected_pc, pc);
            retired = retired + 1;
        end
    endtask

    task automatic check_reg(input int index, input logic [31:0] expected);
        if (dut.rf_unit.rf[index] !== expected)
            $fatal(1, "x%0d: esperado %0d, obtenido %0d", index, expected, dut.rf_unit.rf[index]);
    endtask

    always @(posedge clk) begin
        if (!reset) begin
            if (dut.valid0W) check_retire(dut.pc0W);
            if (dut.valid1W) check_retire(dut.pc1W);

            if (dut.mem_conflict || dut.branch_conflictE ||
                (dut.valid0E && dut.ForwardStall0) || (dut.valid1E && dut.ForwardStall1))
                $fatal(1, "Una instruccion emitida llego a EX o MEM sin su recurso o dato");

            if (dut.MemWrite) begin
                case (dut.MemAddress)
                    32'd0: stores_at_0 = stores_at_0 + 1;
                    32'd4: stores_at_4 = stores_at_4 + 1;
                    default: $fatal(1, "Store inesperado a la direccion %0d", dut.MemAddress);
                endcase
            end
        end
    end

    initial begin
        repeat (2) @(negedge clk);
        reset = 0;
        #1;
        if (dut.IssueCount !== 2'd0 || dut.FetchCount !== 2'd2 || pcF !== 32'd0)
            $fatal(1, "La ventana vacia debe admitir dos instrucciones");

        tick();
        expect_decode(0, 4, 1, 1);
        if (!dut.RAWPair || !dut.PartialIssue || pcF !== 32'd8)
            $fatal(1, "Se esperaba RAW y emision parcial");

        tick();
        expect_decode(4, 8, 2, 2);
        if (pcF !== 32'd12 || {dut.valid1E, dut.valid0E} !== 2'b01 ||
            dut.pc0E !== 32'd0)
            $fatal(1, "La segunda candidata debe desplazarse y reagruparse");
        tick();
        expect_decode(12, 16, 2, 2);
        if ({dut.valid1E, dut.valid0E} !== 2'b11 || dut.pc0E !== 32'd4 ||
            dut.pc1E !== 32'd8 || dut.ForwardAE !== 3'd1 || dut.result0 !== 32'd14)
            $fatal(1, "El par reagrupado debe entrar a EX y usar forwarding");
        $display("PASS: RAW, reagrupamiento, emision doble y forwarding");

        tick();
        expect_decode(20, 24, 1, 1);
        if (!dut.MemWrite1E || !dut.valid1E)
            $fatal(1, "ALU + store deben emitirse con memoria por via 1");
        tick();
        expect_decode(24, 28, 0, 0);
        if (!dut.LoadUseHazard0 || !dut.HoldDecode || pcF !== 32'd32)
            $fatal(1, "Se esperaba stall por load-use de la mas antigua");
        tick();
        expect_decode(24, 28, 2, 2);
        if ({dut.valid1E, dut.valid0E} !== 2'b00 || pcF !== 32'd32)
            $fatal(1, "El stall debe conservar la ventana y el PC e insertar una burbuja");
        $display("PASS: load-use de la mas antigua bloquea ambas vias");

        tick();
        expect_decode(32, 36, 1, 1);
        if (!dut.MemConflictD) $fatal(1, "Se esperaba conflicto de memoria");
        tick();
        expect_decode(36, 40, 2, 2);
        tick();
        expect_decode(44, 48, 1, 1);
        if (dut.ResultSrc0E !== 2'b01 || !dut.valid0E || !dut.valid1E)
            $fatal(1, "Load + ALU deben emitirse con memoria por via 0");
        if (dut.LoadUseHazard0 || !dut.LoadUseHazard1)
            $fatal(1, "Solo la candidata joven debe esperar el load");
        tick();
        expect_decode(48, 52, 2, 2);
        $display("PASS: memoria en ambas vias, conflicto y load-use de la joven");

        tick();
        expect_decode(56, 60, 2, 2);
        tick();
        expect_decode(64, 68, 0, 0);
        if (!dut.branchRedirect || !dut.kill_lane1E)
            $fatal(1, "El salto tomado de la via 0 debe anular la via 1");
        tick();
        if (pcF !== 32'd68 || {valid1D, valid0D} !== 2'b00)
            $fatal(1, "Salto via 0: PC destino o flush incorrecto");
        tick();
        expect_decode(68, 72, 2, 2);
        tick();
        expect_decode(76, 80, 0, 0);
        if (!dut.branchRedirect || dut.kill_lane1E)
            $fatal(1, "El salto tomado de la via 1 debe conservar la via 0");
        tick();
        if (pcF !== 32'd84 || {valid1D, valid0D} !== 2'b00 || !dut.valid0M)
            $fatal(1, "Salto via 1: PC, flush o conservacion incorrectos");

        tick();
        expect_decode(84, 88, 2, 2);
        tick();
        expect_decode(92, 96, 2, 2);
        if (dut.branchRedirect) $fatal(1, "Branch via 0 no tomado redirigio");
        tick();
        expect_decode(100, 104, 1, 1);
        if (dut.branchRedirect || !dut.BranchConflictD)
            $fatal(1, "Branch via 1 no tomado o conflicto de dos saltos incorrecto");
        tick();
        expect_decode(104, 108, 2, 2);
        $display("PASS: saltos en ambas posiciones, flush y conflicto");

        tick();
        expect_decode(112, 116, 2, 2);
        tick();
        expect_decode(120, 124, 2, 2);
        tick();
        expect_decode(128, 132, 2, 2);
        tick();
        expect_decode(136, 140, 0, 0);
        if (!dut.branchRedirect || dut.kill_lane1E || !dut.Jump1E)
            $fatal(1, "JAL de la via 1 debe redirigir y preservar la via 0");
        tick();
        if (pcF !== 32'd144 || {valid1D, valid0D} !== 2'b00)
            $fatal(1, "JAL: PC destino o flush incorrecto");
        tick();
        expect_decode(144, 148, 2, 2);
        if (dut.RegWriteEnable1W !== 1'b1 || dut.rd_1W !== 5'd23 ||
            dut.Result1W !== 32'd136 || dut.RD1_0 !== 32'd136)
            $fatal(1, "Bypass WB1 a Decode incorrecto para x23: WB1=%0d RD1_0=%0d",
                   dut.Result1W, dut.RD1_0);
        repeat (5) tick();

        check_reg(5, 7);
        check_reg(6, 14);
        check_reg(7, 1);
        check_reg(9, 14);
        check_reg(10, 28);
        check_reg(12, 28);
        check_reg(15, 28);
        check_reg(17, 17);
        check_reg(18, 18);
        check_reg(19, 19);
        check_reg(20, 20);
        check_reg(21, 2);
        check_reg(22, 2);
        check_reg(23, 136);
        check_reg(24, 136);
        check_reg(25, 25);
        check_reg(26, 26);
        check_reg(31, 31);
        $display("PASS: JAL, registro de enlace y prioridad de doble writeback");

        if (retired != EXPECTED_RETIRED || stores_at_0 != 1 || stores_at_4 != 1 ||
            dut.dmem_unit.RAM[0] !== 32'd14 || dut.dmem_unit.RAM[1] !== 32'd28)
            $fatal(1, "Conteo de retiro o stores incorrecto");
        $display("PASS: %0d instrucciones retiradas en orden, dos stores y estado final", retired);
        $display("ISSUE INTEGRADO TEST PASSED");
        $finish;
    end
endmodule
