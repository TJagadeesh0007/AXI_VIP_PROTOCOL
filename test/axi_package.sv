package axi_pkg;

	import uvm_pkg::*;
	`include "uvm_macros.svh"

`include "transactions.sv"

`include "axi_master_agent_cfg.sv"
`include "axi_slave_agent_cfg.sv"
`include "axi_env_config.sv"

`include "axi_master_sequence.sv"
`include "axi_master_driver.sv"
`include "axi_master_monitor.sv"
`include "axi_master_sequencer.sv"
`include "axi_master_agent.sv"
`include "axi_master_agent_top.sv"

`include "axi_slave_sequencer.sv"
`include "axi_slave_sequence.sv"
`include "axi_slave_driver.sv"
`include "axi_slave_monitor.sv"
`include "axi_slave_agent.sv"
`include "axi_slave_agent_top.sv"

//`include "router_virtual_sequencer.sv"
//`include "router_virtual_seqs.sv"

`include "axi_sb.sv"

`include "axi_env.sv"

`include "axi_test.sv"

endpackage
