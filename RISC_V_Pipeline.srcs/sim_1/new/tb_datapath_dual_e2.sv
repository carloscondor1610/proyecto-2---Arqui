`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2026 02:16:51 PM
// Design Name: 
// Module Name: tb_datapath_dual_e2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module tb_datapath_dual_e2;

    reg clk = 0;
    reg reset = 0;

    reg [1:0] advance = 0;
    reg redirect = 0;
    reg [31:0] redirect_pc = 0;
    reg stallD = 0;
    reg flushD = 0;

    wire [31:0] pcF, pc1F;
    wire [31:0] instr0D, instr1D;
    wire valid0D, valid1D;
    wire [31:0] result0, result1;

    integer errors = 0;
    integer dual_wb_cycles = 0;
    integer i;

    // ==========================================
    // 1. INSTANCIA DEL DATAPATH DUAL
    // ==========================================

    datapath_dual dut (
        .clk(clk),
        .reset(reset),

        .advance(advance),
        .redirect(redirect),
        .redirect_pc(redirect_pc),
        .stallD(stallD),
        .flushD(flushD),

        .we_test(1'b0),
        .wa_test(5'd0),
        .wd_test(32'd0),

        .pcF(pcF),
        .pc1F(pc1F),

        .instr0D(instr0D),
        .instr1D(instr1D),

        .valid0D(valid0D),
        .valid1D(valid1D),

        .result0(result0),
        .result1(result1)
    );

    // Reloj de 10 ns
    always #5 clk = ~clk;

    // ==========================================
    // 2. CODIFICACION DE INSTRUCCIONES
    // ==========================================

    function automatic [31:0] enc_i(
        input [11:0] imm,
        input [4:0] rs1,
        input [2:0] funct3,
        input [4:0] rd,
        input [6:0] opcode
    );
        enc_i = {
            imm, rs1, funct3, rd, opcode
        };
    endfunction

    function automatic [31:0] enc_s(
        input [11:0] imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] funct3
    );
        enc_s = {
            imm[11:5],
            rs2,
            rs1,
            funct3,
            imm[4:0],
            7'b0100011
        };
    endfunction

    // ==========================================
    // 3. VERIFICACION AUTOMATICA
    // ==========================================

    task automatic check_reg(
        input integer reg_num,
        input [31:0] expected
    );
        begin
            if (dut.rf_unit.rf[reg_num] !== expected) begin

                $display(
                    "FAIL x%0d: esperado=%h obtenido=%h",
                    reg_num,
                    expected,
                    dut.rf_unit.rf[reg_num]
                );

                errors = errors + 1;

            end else begin

                $display(
                    "PASS x%0d = %h",
                    reg_num,
                    expected
                );

            end
        end
    endtask

    task automatic check_mem(
        input integer word_num,
        input [31:0] expected
    );
        begin
            if (dut.dmem_unit.RAM[word_num] !== expected) begin

                $display(
                    "FAIL MEM[%0d]: esperado=%h obtenido=%h",
                    word_num,
                    expected,
                    dut.dmem_unit.RAM[word_num]
                );

                errors = errors + 1;

            end else begin

                $display(
                    "PASS MEM[%0d] = %h",
                    word_num,
                    expected
                );

            end
        end
    endtask

    // ==========================================
    // 4. MONITOREAR DOBLE WRITEBACK
    // ==========================================

    always @(negedge clk) begin

        if (!reset &&
            dut.RegWriteEnable0W &&
            dut.RegWriteEnable1W) begin

            dual_wb_cycles = dual_wb_cycles + 1;

            $display(
                "DUAL WB: x%0d=%h | x%0d=%h",
                dut.rd_0W,
                dut.Result0W,
                dut.rd_1W,
                dut.Result1W
            );

        end

    end

    // ==========================================
    // 5. PROGRAMA DE PRUEBA
    // ==========================================

    initial begin

        $display("================================");
        $display("TEST DATAPATH DUAL ISSUE - E2");
        $display("================================");

        // Esperar inicializacion de memorias
        #1;

        // Rellenar memoria de instrucciones con NOP
        for (i = 0; i < 64; i = i + 1)
            dut.fetch_unit.mem_inst.RAM[i] = 32'h00000013;

        // Inicializar memoria de datos
        dut.dmem_unit.RAM[0] = 32'h807F12A5;
        dut.dmem_unit.RAM[1] = 32'h00000000;
        dut.dmem_unit.RAM[2] = 32'h00000000;

        // Registro preinicializado para probar stores
        dut.rf_unit.rf[16] = 32'h12345678;

        // ======================================
        // PAR 0: DOS ALU INDEPENDIENTES
        // ======================================

        // addi x5, x0, 10
        dut.fetch_unit.mem_inst.RAM[0] =
            enc_i(12'd10, 5'd0, 3'b000, 5'd5, 7'b0010011);

        // addi x6, x0, 20
        dut.fetch_unit.mem_inst.RAM[1] =
            enc_i(12'd20, 5'd0, 3'b000, 5'd6, 7'b0010011);

        // ======================================
        // PAR 1: LOAD + ALU
        // ======================================

        // lw x7, 0(x0)
        dut.fetch_unit.mem_inst.RAM[2] =
            enc_i(12'd0, 5'd0, 3'b010, 5'd7, 7'b0000011);

        // addi x8, x0, 8
        dut.fetch_unit.mem_inst.RAM[3] =
            enc_i(12'd8, 5'd0, 3'b000, 5'd8, 7'b0010011);

        // ======================================
        // PAR 2: ALU + LOAD
        // ======================================

        // addi x9, x0, 9
        dut.fetch_unit.mem_inst.RAM[4] =
            enc_i(12'd9, 5'd0, 3'b000, 5'd9, 7'b0010011);

        // lbu x10, 0(x0)
        dut.fetch_unit.mem_inst.RAM[5] =
            enc_i(12'd0, 5'd0, 3'b100, 5'd10, 7'b0000011);

        // ======================================
        // PAR 3: HALFWORD + ALU
        // ======================================

        // lh x11, 2(x0)
        dut.fetch_unit.mem_inst.RAM[6] =
            enc_i(12'd2, 5'd0, 3'b001, 5'd11, 7'b0000011);

        // addi x12, x0, 12
        dut.fetch_unit.mem_inst.RAM[7] =
            enc_i(12'd12, 5'd0, 3'b000, 5'd12, 7'b0010011);

        // ======================================
        // PAR 4: ALU + STORE WORD
        // ======================================

        // addi x13, x0, 13
        dut.fetch_unit.mem_inst.RAM[8] =
            enc_i(12'd13, 5'd0, 3'b000, 5'd13, 7'b0010011);

        // sw x16, 8(x0)
        dut.fetch_unit.mem_inst.RAM[9] =
            enc_s(12'd8, 5'd16, 5'd0, 3'b010);

        // ======================================
        // PAR 5: BYTE CON SIGNO + ALU
        // ======================================

        // lb x14, 3(x0)
        dut.fetch_unit.mem_inst.RAM[10] =
            enc_i(12'd3, 5'd0, 3'b000, 5'd14, 7'b0000011);

        // addi x15, x0, 15
        dut.fetch_unit.mem_inst.RAM[11] =
            enc_i(12'd15, 5'd0, 3'b000, 5'd15, 7'b0010011);

        // ======================================
        // PAR 6: STORE BYTE + ALU
        // ======================================

        // sb x16, 5(x0)
        dut.fetch_unit.mem_inst.RAM[12] =
            enc_s(12'd5, 5'd16, 5'd0, 3'b000);

        // addi x17, x0, 17
        dut.fetch_unit.mem_inst.RAM[13] =
            enc_i(12'd17, 5'd0, 3'b000, 5'd17, 7'b0010011);

        // ======================================
        // PAR 7: ALU + STORE HALFWORD
        // ======================================

        // addi x18, x0, 18
        dut.fetch_unit.mem_inst.RAM[14] =
            enc_i(12'd18, 5'd0, 3'b000, 5'd18, 7'b0010011);

        // sh x16, 6(x0)
        dut.fetch_unit.mem_inst.RAM[15] =
            enc_s(12'd6, 5'd16, 5'd0, 3'b001);

        // ======================================
        // 6. EJECUTAR PIPELINE
        // ======================================

        #1;
        reset = 1'b1;

        #10;
        reset = 1'b0;
        advance = 2'd2;

        // Emitir ocho pares independientes
        repeat (8)
            @(posedge clk);

        // Detener Fetch y vaciar IF/ID
        @(negedge clk);
        advance = 2'd0;
        flushD = 1'b1;

        @(negedge clk);
        flushD = 1'b0;

        // Permitir que las instrucciones lleguen a WB
        repeat (6)
            @(posedge clk);

        #1;

        // ======================================
        // 7. COMPROBAR REGISTER FILE
        // ======================================

        $display("================================");
        $display("VERIFICACION REGISTER FILE");
        $display("================================");

        check_reg(5,  32'd10);
        check_reg(6,  32'd20);

        check_reg(7,  32'h807F12A5);
        check_reg(8,  32'd8);

        check_reg(9,  32'd9);
        check_reg(10, 32'h000000A5);

        check_reg(11, 32'hFFFF807F);
        check_reg(12, 32'd12);

        check_reg(13, 32'd13);

        check_reg(14, 32'hFFFFFF80);
        check_reg(15, 32'd15);

        check_reg(17, 32'd17);
        check_reg(18, 32'd18);

        // ======================================
        // 8. COMPROBAR MEMORIA
        // ======================================

        $display("================================");
        $display("VERIFICACION MEMORIA");
        $display("================================");

        // SW: escritura de palabra
        check_mem(2, 32'h12345678);

        // SB + SH: escrituras parciales
        check_mem(1, 32'h56787800);

        // ======================================
        // 9. COMPROBAR DOBLE WRITEBACK
        // ======================================

        $display("================================");
        $display("VERIFICACION DUAL WRITEBACK");
        $display("================================");

        if (dual_wb_cycles > 0) begin

            $display(
                "PASS: %0d ciclos con doble Writeback",
                dual_wb_cycles
            );

        end else begin

            $display("FAIL: no hubo doble Writeback");
            errors = errors + 1;

        end

        // ======================================
        // 10. RESULTADO FINAL
        // ======================================

        $display("================================");

        if (errors == 0) begin
            $display("E2 DATAPATH TEST PASSED");
        end else begin
            $display("E2 DATAPATH TEST FAILED");
            $display("Errores: %0d", errors);
        end

        $display("================================");

        $finish;

    end

endmodule
