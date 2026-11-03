
`timescale 1ns / 1ps

module tb_datapath_dual;

    reg clk = 0;
    reg reset = 1;

    reg [1:0] advance = 0;
    reg redirect = 0;
    reg [31:0] redirect_pc = 0;
    reg stallD = 0;
    reg flushD = 0;

    reg we_test = 0;
    reg [4:0] wa_test = 0;
    reg [31:0] wd_test = 0;

    wire [31:0] pcF, pc1F;
    wire [31:0] instr0D, instr1D;
    wire valid0D, valid1D;
    wire [31:0] result0, result1;

    integer errors = 0;

    // ========================================
    // INSTANCIA DEL DATAPATH DUAL
    // ========================================

    datapath_dual dut (
        .clk(clk),
        .reset(reset),
        .advance(advance),
        .redirect(redirect),
        .redirect_pc(redirect_pc),
        .stallD(stallD),
        .flushD(flushD),

        .we_test(we_test),
        .wa_test(wa_test),
        .wd_test(wd_test),

        .pcF(pcF),
        .pc1F(pc1F),
        .instr0D(instr0D),
        .instr1D(instr1D),
        .valid0D(valid0D),
        .valid1D(valid1D),
        .result0(result0),
        .result1(result1)
    );

    // Periodo de reloj: 10 ns
    always #5 clk = ~clk;

    // ========================================
    // TAREA DE VERIFICACION
    // ========================================

    task automatic check(
        input logic condition,
        input string message
    );
        begin
            if (condition !== 1'b1) begin
                $display("FAIL: %s", message);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %s", message);
            end
        end
    endtask

    // ========================================
    // INICIALIZAR REGISTROS
    // ========================================

    task automatic write_reg(
        input [4:0] addr,
        input [31:0] data
    );
        begin
            @(negedge clk);
            we_test = 1;
            wa_test = addr;
            wd_test = data;

            @(posedge clk);
            #1;

            we_test = 0;
        end
    endtask

    // ========================================
    // PRUEBAS
    // ========================================

    initial begin

        $display("==============================");
        $display("INICIO TEST DATAPATH DUAL E1");
        $display("==============================");

        // Reset
        #2;
        reset = 1;
        advance = 0;
        stallD = 1;

        // Inicializar registros para probar
        // ambas vias y cuatro lecturas
        write_reg(5, 10);
        write_reg(6, 20);
        write_reg(8, 3);

        // ====================================
        // PRUEBA 1: DUAL FETCH
        // ====================================

        @(negedge clk);
        reset = 0;
        stallD = 0;
        advance = 2;

        #1;
        check(pcF == 0, "PC inicial = 0");
        check(pc1F == 4, "Segunda direccion = PC+4");

        check(dut.instr0F == 32'h00A00293,
              "Fetch instruccion 0");

        check(dut.instr1F == 32'h01400313,
              "Fetch instruccion 1");

        @(posedge clk);
        #1;

        check(pcF == 8, "PC avanza 8 bytes");

        check(instr0D == 32'h00A00293,
              "IF/ID almacena instruccion 0");

        check(instr1D == 32'h01400313,
              "IF/ID almacena instruccion 1");

        check(dut.pc0D == 0 && dut.pc1D == 4,
              "IF/ID conserva PC0 y PC1");

        check(valid0D && valid1D,
              "Ambas instrucciones validas");

        // ====================================
        // PRUEBA 2: DUAL DECODE
        // ====================================

        check(dut.rs1_0 == 0,
              "rs1 instruccion 0 = x0");

        check(dut.rd_0 == 5,
              "rd instruccion 0 = x5");

        check(dut.rd_1 == 6,
              "rd instruccion 1 = x6");

        check(dut.immext0 == 10,
              "Inmediato 0 = 10");

        check(dut.immext1 == 20,
              "Inmediato 1 = 20");

        check(dut.RegWrite0 && dut.RegWrite1,
              "RegWrite de ambas vias");

        check(dut.ALUSrc0 && dut.ALUSrc1,
              "Ambas ALU usan inmediatos");

        check(result0 == 10,
              "ALU 0 calcula 10");

        check(result1 == 20,
              "ALU 1 calcula 20");

        // ====================================
        // PRUEBA 3: SEGUNDO PAR
        // ====================================

        @(posedge clk);
        #1;

        check(pcF == 16, "PC avanza a 16");

        check(instr0D == 32'h00700393,
              "Instr0: addi x7, x0, 7");

        check(instr1D == 32'h00300413,
              "Instr1: addi x8, x0, 3");

        check(result0 == 7,
              "ALU 0 calcula 7");

        check(result1 == 3,
              "ALU 1 calcula 3");

        // ====================================
        // PRUEBA 4: CUATRO LECTURAS
        // ====================================

        @(posedge clk);
        #1;

        check(pcF == 24, "PC avanza a 24");

        check(instr0D == 32'h005284B3,
              "Instr0: add x9, x5, x5");

        check(instr1D == 32'h00640533,
              "Instr1: add x10, x8, x6");

        check(dut.RD1_0 == 10,
              "Lectura 1 de via 0");

        check(dut.RD2_0 == 10,
              "Lectura 2 de via 0");

        check(dut.RD1_1 == 3,
              "Lectura 1 de via 1");

        check(dut.RD2_1 == 20,
              "Lectura 2 de via 1");

        check(result0 == 20,
              "ALU 0: 10 + 10 = 20");

        check(result1 == 23,
              "ALU 1: 3 + 20 = 23");

        // ====================================
        // PRUEBA 5: STALL
        // ====================================

        @(negedge clk);
        advance = 0;
        stallD = 1;

        @(posedge clk);
        #1;

        check(pcF == 24,
              "Stall mantiene PC");

        check(instr0D == 32'h005284B3,
              "Stall conserva instruccion 0");

        check(instr1D == 32'h00640533,
              "Stall conserva instruccion 1");

        // ====================================
        // PRUEBA 6: AVANCE DE UNA INSTRUCCION
        // ====================================

        @(negedge clk);
        stallD = 0;
        advance = 1;

        @(posedge clk);
        #1;

        check(pcF == 28, "PC avanza 4 bytes");

        check(instr0D == 32'h00100593,
              "Captura instruccion de PC=24");

        check(valid0D == 1 && valid1D == 0,
              "Solo primera instruccion valida");

        // ====================================
        // PRUEBA 7: FLUSH
        // ====================================

        @(negedge clk);
        advance = 0;
        flushD = 1;

        @(posedge clk);
        #1;

        check(valid0D == 0 && valid1D == 0,
              "Flush invalida ambas instrucciones");

        // ====================================
        // PRUEBA 8: REDIRECT
        // ====================================

        @(negedge clk);
        flushD = 0;
        redirect = 1;
        redirect_pc = 0;

        @(posedge clk);
        #1;

        check(pcF == 0,
              "Redirect devuelve PC a cero");

        // ====================================
        // RESULTADO FINAL
        // ====================================

        $display("==============================");

        if (errors == 0) begin
            $display("DUAL DATAPATH TEST PASSED");
        end
        else begin
            $display("DUAL DATAPATH TEST FAILED");
            $display("Errores encontrados: %0d", errors);
            $fatal(1);
        end

        $display("==============================");

        $finish;
    end

endmodule
