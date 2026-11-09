`timescale 1ns / 1ps

module dmem_dual #(
    parameter DEPTH = 256
)(
    input wire clk,

    // Control de memoria compartida
    input wire memwrite,
    input wire [31:0] address,
    input wire [31:0] writedata,

    // Tipo de acceso RV32I
    input wire [2:0] funct3,

    // Resultado de lectura
    output reg [31:0] readdata
);

    // Memoria de 256 palabras de 32 bits
    reg [31:0] RAM [0:DEPTH-1];

    wire [7:0] byte_data;
    wire [15:0] half_data;
    wire [31:0] word_data;

    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            RAM[i] = 32'd0;
    end

    // ======================================
    // 1. LECTURA DE MEMORIA
    // ======================================

    assign word_data = RAM[address[9:2]];

    // Seleccion de byte
    assign byte_data =
        (address[1:0] == 2'b00) ? word_data[7:0] :
        (address[1:0] == 2'b01) ? word_data[15:8] :
        (address[1:0] == 2'b10) ? word_data[23:16] :
                                 word_data[31:24];

    // Seleccion de halfword
    assign half_data =
        address[1] ? word_data[31:16] :
                     word_data[15:0];

    // ======================================
    // 2. EXTENSION DE DATOS RV32I
    // ======================================

    always @(*) begin
        case (funct3)

            // LB - Byte con signo
            3'b000:
                readdata = {{24{byte_data[7]}}, byte_data};

            // LH - Halfword con signo
            3'b001:
                readdata = {{16{half_data[15]}}, half_data};

            // LW - Word
            3'b010:
                readdata = word_data;

            // LBU - Byte sin signo
            3'b100:
                readdata = {24'd0, byte_data};

            // LHU - Halfword sin signo
            3'b101:
                readdata = {16'd0, half_data};

            default:
                readdata = 32'd0;

        endcase
    end

    // ======================================
    // 3. ESCRITURA DE MEMORIA
    // ======================================

    always @(posedge clk) begin
        if (memwrite) begin

            case (funct3)

                // SB - Store Byte
                3'b000: begin
                    case (address[1:0])
                        2'b00:
                            RAM[address[9:2]][7:0]
                                <= writedata[7:0];

                        2'b01:
                            RAM[address[9:2]][15:8]
                                <= writedata[7:0];

                        2'b10:
                            RAM[address[9:2]][23:16]
                                <= writedata[7:0];

                        2'b11:
                            RAM[address[9:2]][31:24]
                                <= writedata[7:0];
                    endcase
                end

                // SH - Store Halfword
                3'b001: begin
                    if (address[0] == 1'b0) begin
                        if (address[1] == 1'b0)
                            RAM[address[9:2]][15:0]
                                <= writedata[15:0];
                        else
                            RAM[address[9:2]][31:16]
                                <= writedata[15:0];
                    end
                end

                // SW - Store Word
                3'b010: begin
                    if (address[1:0] == 2'b00)
                        RAM[address[9:2]]
                            <= writedata;
                end

                default: begin
                    // Operacion no soportada
                end

            endcase
        end
    end

endmodule