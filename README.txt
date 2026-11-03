RISC-V PIPELINE RV32I - BASE SINGLE-ISSUE (INTEGRANTE 1)
=========================================================

ORIGEN
16 modulos Verilog y testbench suministrados por el integrante 1.
Cada archivo separado y conservado sin cambios funcionales intencionales.
No se agrega design.sv de EDA Playground porque Vivado compila los archivos .v individualmente; incluir ambos duplicaria modulos.

CARPETAS
src/   : 16 modulos del procesador.
sim/   : testbench.sv y riscvtest.dat (64 palabras hexadecimales).
create_project.tcl : script de creacion del proyecto en Vivado.

IMPORTAR EN VIVADO
1) Descomprime el ZIP en una ruta corta, sin caracteres especiales.
2) Abre Vivado y en Tools > Run Tcl Script ejecuta create_project.tcl.
   Otra opcion: ejecuta en la consola Tcl: source /ruta/create_project.tcl
3) El script crea Vivado_Project/ con todos los archivos agregados.
4) Abre Run Simulation > Run Behavioral Simulation.
5) El testbench termina automaticamente, imprimiendo REGRESSION TEST PASSED si pasa.

IMPORTANTE SOBRE LA FPGA
Sin una placa/FPGA especifica, el script utiliza xc7a35tcpg236-1 como ejemplo.
Para otra parte, antes de ejecutar el script en Tcl puedes definir:
    set ::env(VIVADO_PART) xc7a100tcsg324-1
(Reemplaza la parte de ejemplo por el identificador real.)
No se incluyen restricciones XDC de placa; el objetivo del paquete es simulacion y continuidad del RTL.

NOTAS TECNICAS
- La instancia se llama 'rvsingle' en top.v para conservar las rutas del testbench; usa datapath_pipeline, no riscvsingle.
- El PC maneja casos de beq/jal en EX y anula instrucciones mas jovenes de forma basica.
- StallF y StallD estan fijados en cero; no hay forwarding ni stalling funcionales.
- La memoria es de palabras; accesos byte/halfword no estan implementados.
- Solo se soporta un subconjunto de RV32I, no el ISA completo.
- El programa de pruebas evita dependencias RAW con nop donde es necesario.
- Este paquete conserva el esquema $readmemh("riscvtest.dat", RAM); para que la memoria cargue el archivo de pruebas. Vivado debe encontrarlo como archivo de simulacion; si no, comprueba la ruta de trabajo o el copiado de .dat al directorio de simulacion.
- El testbench tiene $dumpvars; la compatibilidad de la visualizacion VCD depende del simulador. Para XSim se puede usar la ventana de ondas de Vivado.

VALIDACION
El usuario reporto en EDA Playground: REGRESSION TEST PASSED (29 registros y MEM[100]).
Esta exportacion se revisa estaticamente, pero no equivale a una simulacion en Vivado.
