//slave  agent

class slave_agent extends uvm_agent;
`uvm_component_utils(slave_agent)

axi_slave_agent_config slave_agent_cfg;

	slave_monitor slave_monh;
	slave_sequencer slave_seqrh;
	slave_driver slave_drvh;

function new(string name = "slave_agent", uvm_component parent = null);
	super.new(name, parent);
endfunction
     
function void build_phase(uvm_phase phase);
	super.build_phase(phase);

	if(!uvm_config_db #(axi_slave_agent_config)::get(this,"","axi_slave_agent_config",slave_agent_cfg))
	`uvm_fatal("S_AGT CONFIG","cannot get() slave_agent_cfg from uvm_config_db. Have you set() it?")  
//	slave_agent_cfg = axi_slave_agent_config::type_id::create("slave_agent_cfg");

    	slave_monh = slave_monitor::type_id::create("slave_monh",this);	
	if(slave_agent_cfg.is_active == UVM_ACTIVE)
		begin
			slave_drvh = slave_driver::type_id::create("slave_drvh",this);
			slave_seqrh = slave_sequencer::type_id::create("slave_seqrh",this);
		end
endfunction
      
function void connect_phase(uvm_phase phase);
	if(slave_agent_cfg.is_active==UVM_ACTIVE)
		begin
			slave_drvh.seq_item_port.connect(slave_seqrh.seq_item_export);
		end
endfunction
endclass
