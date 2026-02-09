class axi_test extends uvm_test;
`uvm_component_utils(axi_test)

axi_env envh;
axi_env_config env_cfg;
axi_master_agent_config master_cfg[];
axi_slave_agent_config slave_cfg[];

bit has_master_agent = 1;
bit has_slave_agent = 1;

int no_of_master_agents = 1;
int no_of_slave_agents = 1;

function new(string name = "axi_test",uvm_component parent = null);
	super.new(name,parent);
endfunction

function void config_axi();
	if(has_master_agent)
	begin	
		foreach(master_cfg[i])
		begin
			if(!uvm_config_db #(virtual axi_if)::get(this,"","axi_if",master_cfg[i].vif))
			`uvm_fatal(get_type_name(),"getting source agent interface failed")	
			master_cfg[i].is_active = UVM_ACTIVE;
		end
	end

	if(has_slave_agent)
	begin
		foreach(slave_cfg[i])
		begin
			if(!uvm_config_db #(virtual axi_if)::get(this,"","axi_if",slave_cfg[i].vif))
			`uvm_fatal(get_type_name(),"getting destination agent interface failed")	
	 		slave_cfg[i].is_active = UVM_ACTIVE;
end
end

env_cfg.master_cfg = master_cfg;
env_cfg.slave_cfg = slave_cfg;

env_cfg.no_of_master_agents = no_of_master_agents;
env_cfg.no_of_slave_agents = no_of_slave_agents;

	uvm_config_db #(axi_env_config)::set(this,"*","axi_env_config",env_cfg);

endfunction

function void build_phase(uvm_phase phase);
	super.build_phase(phase);

	env_cfg = axi_env_config::type_id::create("env_cfg");

	if(has_master_agent)
		master_cfg = new[no_of_master_agents];
		foreach(master_cfg[i])
		begin
			master_cfg[i] = axi_master_agent_config::type_id::create($sformatf("master_cfg[%0d]",i));
		end

	if(has_slave_agent)
		slave_cfg = new[no_of_slave_agents];
		foreach(slave_cfg[i])
		begin
			slave_cfg[i] = axi_slave_agent_config::type_id::create($sformatf("slave_cfg[%0d]",i));
		end

	config_axi();

	envh = axi_env::type_id::create("envh",this);

endfunction

function void start_of_simulation_phase(uvm_phase phase);
	super.start_of_simulation_phase(phase);
	uvm_top.print_topology();
endfunction

endclass

//---------------------------------------------------------------//
//-------------------------TEST CASES-----------------------------//
//-----------------------------------------------------------------//

class fixed_test extends axi_test;
`uvm_component_utils(fixed_test)

master_seq_fixed master_fixed_seqh;
slave_seq_fixed slave_fixed_seqh;

function new(string name = "fixed_test" , uvm_component parent);
	super.new(name,parent);
endfunction
            
function void build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction

task run_phase(uvm_phase phase);

	master_fixed_seqh = master_seq_fixed::type_id::create("master_fixed_seqh");
	slave_fixed_seqh  = slave_seq_fixed :: type_id::create("slave_fixed_seqh");
       phase.raise_objection(this);
     	repeat(25)
	  fork
  		master_fixed_seqh.start(envh.master_agt_top.master_agnth[0].master_seqrh);
		slave_fixed_seqh.start(envh.slave_agt_top.slave_agnth[0].slave_seqrh);
  	  join
	#40000;

       phase.drop_objection(this);
endtask   

endclass

//===========================================================================//

class incr_test extends axi_test;
`uvm_component_utils(incr_test)

master_seq_incr master_incr_seqh;
slave_seq_incr slave_incr_seqh;

function new(string name = "incr_test" , uvm_component parent);
	super.new(name,parent);
endfunction
            
function void build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction

task run_phase(uvm_phase phase);

	master_incr_seqh = master_seq_incr::type_id::create("master_incr_seqh");
	slave_incr_seqh = slave_seq_incr::type_id::create("slave_incr_seqh");

       phase.raise_objection(this);
     	repeat(25)
	fork
    		master_incr_seqh.start(envh.master_agt_top.master_agnth[0].master_seqrh);
    		slave_incr_seqh.start(envh.slave_agt_top.slave_agnth[0].slave_seqrh);	
	
	join
	#25000;
       phase.drop_objection(this);
endtask   

endclass

//========================================================================//

class wrap_test extends axi_test;
`uvm_component_utils(wrap_test)

master_seq_wrap master_wrap_seqh;
slave_seq_wrap slave_wrap_seqh;

function new(string name = "wrap_test" , uvm_component parent);
	super.new(name,parent);
endfunction
            
function void build_phase(uvm_phase phase);
    super.build_phase(phase);
endfunction

task run_phase(uvm_phase phase);

	master_wrap_seqh = master_seq_wrap::type_id::create("master_wrap_seqh");
	slave_wrap_seqh = slave_seq_wrap::type_id::create("slave_wrap_seqh");

       phase.raise_objection(this);
     	repeat(25)
	fork
    		master_wrap_seqh.start(envh.master_agt_top.master_agnth[0].master_seqrh);
    		slave_wrap_seqh.start(envh.slave_agt_top.slave_agnth[0].slave_seqrh);	
	
	join
	#25000;
       phase.drop_objection(this);
endtask   

endclass


