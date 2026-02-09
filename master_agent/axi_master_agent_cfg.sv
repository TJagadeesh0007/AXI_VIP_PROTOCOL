// Master agent configuration 

class axi_master_agent_config extends uvm_object;
`uvm_object_utils(axi_master_agent_config)

virtual axi_if vif;
uvm_active_passive_enum is_active = UVM_ACTIVE;

function new(string name = "axi_master_agent_config");
	super.new(name);
endfunction

endclass

