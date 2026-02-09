// slave sequence

class slave_base_sequence extends uvm_sequence #(axi_xtn);
`uvm_object_utils(slave_base_sequence)

axi_slave_agent_config slave_agent_cfg;  	

function new(string name ="slave_base_sequence");
	super.new(name);
endfunction
endclass
//=========================SEQUENCES===============================//

class slave_seq_fixed extends slave_base_sequence;
`uvm_object_utils(slave_seq_fixed)
	
function new(string name = "slave_seq_fixed");
	super.new(name);
endfunction

task body();
	 // repeat(50)
	  begin
   	   req = axi_xtn::type_id::create("req");
	   start_item(req);
   	   assert(req.randomize() with {awburst == 0; arburst == 0; awsize inside {[0:2]}; arsize inside {[0:2]};})
	   finish_item(req); 
	end
endtask
endclass

//===========================================================//

class slave_seq_incr extends slave_base_sequence;
`uvm_object_utils(slave_seq_incr)
	
function new(string name = "slave_seq_incr");
	super.new(name);
endfunction

task body();
	//  repeat(50)
	  begin
   	   req = axi_xtn::type_id::create("req");
	   start_item(req);
   	   assert(req.randomize() with {awburst == 1; arburst == 1; awsize inside {[0:2]}; arsize inside {[0:2]};})
	   finish_item(req); 
	end
endtask
endclass

//============================================================//

class slave_seq_wrap extends slave_base_sequence;
`uvm_object_utils(slave_seq_wrap)
	
function new(string name = "slave_seq_wrap");
	super.new(name);
endfunction

task body();
//	  repeat(50)
	  begin
   	   req = axi_xtn::type_id::create("req");
	   start_item(req);
   	   assert(req.randomize() with {awburst == 2; arburst == 2; awsize inside {[0:2]}; arsize inside {[0:2]};})
	   finish_item(req); 
	end
endtask
endclass

//==============================================================//

/*class slave_seq_random extends slave_base_sequence;
`uvm_object_utils(slave_seq_random)
	
function new(string name = "slave_seq_random");
	super.new(name);
endfunction

task body();
	  repeat(50)
	  begin
   	   req = axi_xtn::type_id::create("req");
	   start_item(req);
   	   assert(req.randomize())
	   finish_item(req); 
	  end

	  repeat(50)
	  begin
   	   req = axi_xtn::type_id::create("req");
	   start_item(req);
   	   assert(req.randomize() with {awsize == 0; arsize == 0;})
	   finish_item(req); 
	  end


	  repeat(50)
	  begin
   	   req = axi_xtn::type_id::create("req");
	   start_item(req);
   	   assert(req.randomize() with {awsize == 1; arsize == 1;})

	   finish_item(req); 
	  end
endtask
endclass

*/



