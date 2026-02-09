// slave agent configuration 

class axi_slave_agent_config extends uvm_object;
`uvm_object_utils(axi_slave_agent_config)

virtual axi_if vif;
uvm_active_passive_enum is_active = UVM_ACTIVE;

function new(string name = "axi_slave_agent_config");
	super.new(name);
endfunction

endclass

