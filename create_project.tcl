set root [file dirname [file normalize [info script]]]
set project_dir [file join $root Vivado_Project]

if {[info exists ::env(VIVADO_PART)] && $::env(VIVADO_PART) ne ""} {
    set selected_part $::env(VIVADO_PART)
} elseif {[llength $argv] >= 1 && [lindex $argv 0] ne ""} {
    set selected_part [lindex $argv 0]
} else {
    set selected_part "xc7a35tcpg236-1"
    puts "NOTICE: Usando una FPGA de ejemplo ($selected_part). Cambia la parte si usaras otra placa."
}

create_project -force RISC_V_Pipeline $project_dir -part $selected_part
set src_dir [file join $root src]
set sim_dir [file join $root sim]

foreach verilog_file [glob -nocomplain -directory $src_dir *.v] {
    add_files -fileset sources_1 $verilog_file
}
set_property top top [get_filesets sources_1]
update_compile_order -fileset sources_1

add_files -fileset sim_1 [file join $sim_dir testbench.sv]
add_files -fileset sim_1 [file join $sim_dir riscvtest.dat]
set_property file_type {Memory File} [get_files [file join $sim_dir riscvtest.dat]]
set_property top testbench [get_filesets sim_1]
update_compile_order -fileset sim_1

set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_1]
puts "Proyecto creado en: $project_dir"
puts "Para simular en la GUI: Flow Navigator > Simulation > Run Simulation > Run Behavioral Simulation"
puts "Nota: el procesador es una base Single-Issue, no el Dual-Issue final."
