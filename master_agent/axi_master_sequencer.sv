// master sequencer

class master_sequencer extends uvm_sequencer #(axi_xtn);
`uvm_component_utils(master_sequencer)

axi_master_agent_config master_agent_cfg;  	

function new(string name ="master_sequencer",uvm_component parent);
	super.new(name,parent);
endfunction

endclass

