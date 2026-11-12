# Ejecutar en Tcl Console con tb_issue_integrado abierto en XSim.
set e2_tb /tb_issue_integrado
set e2_dut $e2_tb/dut

if {[llength [get_objects -quiet $e2_dut/IssueCount]] == 0 ||
    [llength [get_objects -quiet $e2_tb/retired]] == 0} {
    error "Abre la simulacion tb_issue_integrado antes de ejecutar este script."
}

proc e2_crear_vista {name testbench signal_names} {
    set cfg [create_wave_config $name]
    foreach name_of_signal $signal_names {
        if {$name_of_signal in {clk retired}} {
            set path $testbench/$name_of_signal
        } else {
            set path $testbench/dut/$name_of_signal
        }

        set obj [get_objects -quiet $path]
        if {[llength $obj] != 1} {
            error "La senal $path no esta disponible en la simulacion."
        }
        add_wave -into $cfg -radix unsigned $obj
    }
    return $cfg
}

set e2_raw [e2_crear_vista Figura_7_RAW $e2_tb {
    clk pc0D pc1D RAWPair BlockIssue1 Issue0 Issue1 PartialIssue IssueCount ForwardAE result0
}]
e2_crear_vista Figura_8a_Memoria $e2_tb {
    clk pc0D pc1D MemConflictD Issue0 Issue1 PartialIssue IssueCount mem_conflict
}
e2_crear_vista Figura_8b_Branches $e2_tb {
    clk pc0D pc1D BranchConflictD Issue0 Issue1 PartialIssue IssueCount branch_conflictE
}
e2_crear_vista Figura_9_Reagrupamiento $e2_tb {
    clk pc0D pc1D PartialIssue FetchCount IssueCount pc0E pc1E valid0E valid1E
}
e2_crear_vista Figura_10_Retiro $e2_tb {
    clk pc0W valid0W pc1W valid1W retired
}

restart
run all
current_wave_config $e2_raw

puts "Rangos sugeridos en ns: RAW 20-50, memoria 75-110, branches 195-230, reagrupamiento 20-50, retiro 265-326."
