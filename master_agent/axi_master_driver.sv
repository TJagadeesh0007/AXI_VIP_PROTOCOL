// master driver

class master_driver extends uvm_driver #(axi_xtn);
`uvm_component_utils(master_driver)

virtual axi_if.MASTER_DRV vif;
axi_master_agent_config master_agent_cfg;  	

axi_xtn xtn;
axi_xtn q1[$], q2[$], q3[$], q4[$], q5[$];

semaphore sem_wdc = new(1); //write data channel
semaphore sem_wac = new(1); //write address channel
semaphore sem_wrc = new(1); //write response channel
semaphore sem_ewdc = new(); //extra write data channel
semaphore sem_ewac = new(); //extra write address channel

semaphore sem_arc = new(1); //read address data channel
semaphore sem_rdc = new(1); //read data channel
semaphore sem_earc = new(); //extra read address data channel

function new(string name ="master_driver",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db #(axi_master_agent_config)::get(this,"","axi_master_agent_config",master_agent_cfg))
		`uvm_fatal(get_type_name(),"getting master cfg in master driver failed")
endfunction

function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	vif = master_agent_cfg.vif;
endfunction

task run_phase(uvm_phase phase);
	super.run_phase(phase);
	//	@(vif.master_drv_cb);
	//	vif.master_drv_cb.aresetn <= 1'b0;
	//	@(vif.master_drv_cb);
	//	vif.master_drv_cb.aresetn <= 1'b1;

	forever
	begin
		seq_item_port.get_next_item(req);
		drive_to_dut(req);
		seq_item_port.item_done();
		`uvm_info("MASTER_DRIVER",$sformatf("printing from master driver \n %s", req.sprint()),UVM_LOW)

	end
endtask

task drive_to_dut(axi_xtn xtn);
	q1.push_back(xtn);
	q2.push_back(xtn);
	q3.push_back(xtn);
	q4.push_back(xtn);
	q5.push_back(xtn);
	
	fork
	//write address channel	
	begin	
		sem_wac.get(1);
		drive_awaddr(q1.pop_front());
		sem_ewdc.put(1); //after write address channel we have to start data channel so we pass the key
		sem_wac.put(1);
	end
	
	//write data channel
	begin
		sem_ewdc.get(1);
		sem_wdc.get(1);
		drive_wdata(q2.pop_front());
		sem_wdc.put(1);
		sem_ewac.put(1);
	end
	
	//response channel
	begin
		sem_ewac.get(1);
		sem_wrc.get(1);
		drive_bresp(q3.pop_front());
		sem_wrc.put(1);
	end

	//read address channel
	begin
		sem_arc.get(1);
		drive_raddr(q4.pop_front());
		sem_arc.put(1);
		sem_earc.put(1);
	end

	//read data channel
	begin	
		sem_earc.get(1);
		sem_rdc.get(1);
		drive_rdata(q5.pop_front());
		sem_rdc.put(1);
	end
	join_any

endtask

task drive_awaddr(axi_xtn xtn);
	$display("Start of drive_awaddr");
	vif.master_drv_cb.awvalid <= 1;	
	vif.master_drv_cb.awaddr <= xtn.awaddr;
	vif.master_drv_cb.awsize <= xtn.awsize;
	vif.master_drv_cb.awid <= xtn.awid;
	vif.master_drv_cb.awlen <= xtn.awlen;
	vif.master_drv_cb.awburst <= xtn.awburst;
	@(vif.master_drv_cb);

	wait(vif.master_drv_cb.awready)
	vif.master_drv_cb.awvalid <= 0;
	
	repeat($urandom_range(1,5))
	@(vif.master_drv_cb);

	$display("End of drive_awaddr");
endtask

task drive_wdata(axi_xtn xtn);
	$display("Start of drive_wdata");
	foreach(xtn.wdata[i])
	begin
		vif.master_drv_cb.wvalid <= 1;
		vif.master_drv_cb.wdata <= xtn.wdata[i];
		vif.master_drv_cb.wstrb <= xtn.wstrb[i];
		vif.master_drv_cb.wid <= xtn.wid;
		if(i == xtn.awlen)
			vif.master_drv_cb.wlast <= 1'b1;
		else
			vif.master_drv_cb.wlast <= 1'b0;

		@(vif.master_drv_cb);

		wait(vif.master_drv_cb.wready)
			vif.master_drv_cb.wvalid <= 1'b0;
			vif.master_drv_cb.wlast <= 1'b0;

		repeat($urandom_range(1,5))
//	repeat(2)
		@(vif.master_drv_cb);
	end	
	$display("End of drive_wdata");
endtask

task drive_bresp(axi_xtn xtn);
	$display("Start of drive_bresp");

	vif.master_drv_cb.bready <= 1'b1;
		@(vif.master_drv_cb);

	wait(vif.master_drv_cb.bvalid)
	vif.master_drv_cb.bready <= 1'b0;

	repeat($urandom_range(1,5))
//	repeat(2)
	@(vif.master_drv_cb);
	
	$display("End of drive_bresp");
endtask

task drive_raddr(axi_xtn xtn);
	$display("Start of drive_raddr");
	repeat($urandom_range(1,5))
	@(vif.master_drv_cb);
        vif.master_drv_cb.arvalid <= 1;

	vif.master_drv_cb.arid <= xtn.arid;
	vif.master_drv_cb.arlen <= xtn.arlen;
	vif.master_drv_cb.arsize <= xtn.arsize;
	vif.master_drv_cb.arburst <= xtn.arburst;
	vif.master_drv_cb.araddr <= xtn.araddr;
	@(vif.master_drv_cb);
			

//	q5.push_back(xtn);
//	@(vif.master_drv_cb);
		
	wait(vif.master_drv_cb.arready)		
	vif.master_drv_cb.arvalid <= 0;

	repeat($urandom_range(1,5))
//	repeat(2)
	@(vif.master_drv_cb);
			
	$display("End of drive_raddr");
endtask

task drive_rdata(axi_xtn xtn);
	int mem[int];
	$display("Start of drive_rdata");
	
	xtn.cal_raddr();

	for(int i = 0; i < (xtn.arlen + 1); i++)
		begin
			vif.master_drv_cb.rready <= 1;
			@(vif.master_drv_cb);
			
			wait(vif.master_drv_cb.rvalid)		
			vif.master_drv_cb.rready <= 0;
		
		//	repeat($urandom_range(1,5))
			repeat(2)
			@(vif.master_drv_cb);
		end
		
		$display("master recieved address: %p",xtn.raddr);
		$display("memory recieved in master driver is %p", mem);
endtask

endclass


/*semaphore sem1 = new(1);
semaphore sem2 = new();
semaphore sem3 = new();
semaphore sem4 = new(1);
semaphore sem5 = new();*/

/*	fork
	//write address channel	
	begin	
		sem1.get(1);
		drive_awaddr(q1.pop_front());
		sem2.put(1); //after write address channel we have to start data channel so we pass the key
		sem1.put(1);
	end
	
	//write data channel
	begin
		sem2.get(1);
		drive_wdata(q2.pop_front());
		sem3.put(1);
		sem2.put(1);
	end
	
	//response channel
	begin
		sem3.get(1);
		drive_bresp(q3.pop_front());
		sem3.put(1);
	end

	//read address channel
	begin
		sem4.get(1);
		drive_raddr(q4.pop_front());
		sem5.put(1);
		sem4.put(1);
	end

	//read data channel
	begin	
		sem5.get(1);
		drive_rdata(q5.pop_front());
		sem5.put(1);
	end
	join_any
*/


