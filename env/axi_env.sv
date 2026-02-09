// axi Environment

class axi_env extends uvm_env;
`uvm_component_utils(axi_env)

master_agent_top master_agt_top;
slave_agent_top slave_agt_top;

axi_scoreboard sb;

axi_env_config env_cfg;
axi_master_agent_config master_cfg;
axi_slave_agent_config slave_cfg;

//axi_v_sequencer v_sqrh;

int no_of_master_agents = 1;
int no_of_slave_agents = 1;


function new(string name = "axi_env", uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	if(!uvm_config_db #(axi_env_config)::get(this,"","axi_env_config",env_cfg))
		`uvm_fatal(get_type_name(),"getting env config has failed")
	
	if(env_cfg.has_master_agent)
		begin
			master_agt_top = master_agent_top::type_id::create("master_agt_top",this);
		end

	if(env_cfg.has_slave_agent)
		begin	
			slave_agt_top = slave_agent_top::type_id::create("slave_agt_top",this);
		end
  
	super.build_phase(phase);
//	v_sqrh = axi_v_sequencer::type_id::create("v_sqrh",this);
	
	if(env_cfg.has_scoreboard)
	           sb = axi_scoreboard::type_id::create("sb",this);
	
endfunction

function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);

	if(env_cfg.has_master_agent)
		begin
			master_agt_top.master_agnth[0].master_monh.master_mon_ap.connect(sb.master_fifoh[0].analysis_export);
		//	v_sqrh.src_seqrh[i] = src_agt_top[i].src_agnth[i].seqrh;                    
		end
                      
	if(env_cfg.has_slave_agent) 
		begin
			slave_agt_top.slave_agnth[0].slave_monh.slave_mon_ap.connect(sb.slave_fifoh[0].analysis_export);
	         //      v_sqrh.dst_seqrh[i] = dst_agt_top[0].dst_agnth[i].seqrh;
		end
endfunction

endclass

