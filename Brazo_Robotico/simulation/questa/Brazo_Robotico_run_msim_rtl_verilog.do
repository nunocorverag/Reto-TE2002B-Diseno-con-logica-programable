transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/andyq/Documents/QuartusProjects/logica_prog/Reto-TE2002B-Diseno-con-logica-programable/Brazo_Robotico/pwm {C:/Users/andyq/Documents/QuartusProjects/logica_prog/Reto-TE2002B-Diseno-con-logica-programable/Brazo_Robotico/pwm/pwm_mapeo.v}
vlog -vlog01compat -work work +incdir+C:/Users/andyq/Documents/QuartusProjects/logica_prog/Reto-TE2002B-Diseno-con-logica-programable/Brazo_Robotico/pwm {C:/Users/andyq/Documents/QuartusProjects/logica_prog/Reto-TE2002B-Diseno-con-logica-programable/Brazo_Robotico/pwm/pwm_servos.v}

vlog -vlog01compat -work work +incdir+C:/Users/andyq/Documents/QuartusProjects/logica_prog/Reto-TE2002B-Diseno-con-logica-programable/Brazo_Robotico/pwm {C:/Users/andyq/Documents/QuartusProjects/logica_prog/Reto-TE2002B-Diseno-con-logica-programable/Brazo_Robotico/pwm/pwm_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -voptargs="+acc"  pwm_tb

add wave *
view structure
view signals
run -all
