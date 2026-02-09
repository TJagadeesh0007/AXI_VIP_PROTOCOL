//Master  agent

class master_agent extends uvm_agent;
`uvm_component_utils(master_agent)

axi_master_agent_config master_agent_cfg;

	master_monitor master_monh;
	master_sequencer master_seqrh;
	master_driver master_drvh;

function new(string name = "master_agent", uvm_component parent = null);
	super.new(name, parent);
endfunction
     
function void build_phase(uvm_phase phase);
	super.build_phase(phase);

	if(!uvm_config_db #(axi_master_agent_config)::get(this,"","axi_master_agent_config",master_agent_cfg))
	`uvm_fatal("M_AGT CONFIG","cannot get() master_agent_cfg from uvm_config_db. Have you set() it?")  
//	master_agent_cfg = axi_master_agent_config::type_id::create("master_agent_cfg");

    	master_monh = master_monitor::type_id::create("master_monh",this);	
	if(master_agent_cfg.is_active == UVM_ACTIVE)
		begin
			master_drvh = master_driver::type_id::create("master_drvh",this);
			master_seqrh = master_sequencer::type_id::create("master_seqrh",this);
		end
endfunction
      
function void connect_phase(uvm_phase phase);
	if(master_agent_cfg.is_active==UVM_ACTIVE)
		begin
			master_drvh.seq_item_port.connect(master_seqrh.seq_item_export);
		end
endfunction
endclass
