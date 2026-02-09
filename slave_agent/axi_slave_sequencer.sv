// slave sequencer

class slave_sequencer extends uvm_sequencer #(axi_xtn);
`uvm_component_utils(slave_sequencer)

axi_slave_agent_config slave_agent_cfg;  	

function new(string name ="slave_sequencer",uvm_component parent);
	super.new(name,parent);
endfunction

endclass

