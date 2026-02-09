// Master Agent top

class master_agent_top extends uvm_env;
`uvm_component_utils(master_agent_top)

axi_env_config env_cfg;    
master_agent master_agnth[];

function new(string name = "master_agent_top" , uvm_component parent);
	super.new(name,parent);
endfunction

    
function void build_phase(uvm_phase phase);
     super.build_phase(phase);
	if(!uvm_config_db #(axi_env_config)::get(this,"","axi_env_config",env_cfg))
	`uvm_fatal(get_type_name(),"getting env_configuration failed")

	master_agnth = new[env_cfg.no_of_master_agents];

   	if(env_cfg.no_of_master_agents)
	begin
		foreach(master_agnth[i])
		begin
		uvm_config_db #(axi_master_agent_config)::set(this,"*","axi_master_agent_config",env_cfg.master_cfg[i]);
   		master_agnth[i] = master_agent::type_id::create($sformatf("master_agnth[%0d]",i),this);
		end
	end
endfunction

endclass

