// slave Agent top

class slave_agent_top extends uvm_env;
`uvm_component_utils(slave_agent_top)

axi_env_config env_cfg;    
slave_agent slave_agnth[];

function new(string name = "slave_agent_top" , uvm_component parent);
	super.new(name,parent);
endfunction

    
function void build_phase(uvm_phase phase);
     super.build_phase(phase);
	if(!uvm_config_db #(axi_env_config)::get(this,"","axi_env_config",env_cfg))
	`uvm_fatal(get_type_name(),"getting env_configuration failed")

//	env_cfg = axi_env_config::type_id::create("env_cfg");

	slave_agnth = new[env_cfg.no_of_slave_agents];

   	if(env_cfg.no_of_slave_agents)
	begin
		foreach(slave_agnth[i])
		begin
		uvm_config_db #(axi_slave_agent_config)::set(this,"*","axi_slave_agent_config",env_cfg.slave_cfg[i]);
   		slave_agnth[i] = slave_agent::type_id::create($sformatf("slave_agnth[%0d]",i),this);
		end
	end
endfunction

endclass

