// slave driver

class slave_driver extends uvm_driver #(axi_xtn);
`uvm_component_utils(slave_driver)

virtual axi_if.SLAVE_DRV vif;
axi_slave_agent_config slave_agent_cfg;  	

axi_xtn xtn,xtn1;
axi_xtn q1[$], q2[$], q3[$];


semaphore sem_awdata = new(1); //write data channel
semaphore sem_awaddr = new(1); //write address channel
semaphore sem_wrp = new(1); //write response channel
semaphore sem_awad = new(); //extra write data channel
semaphore sem_wdrp = new(); //extra write address channel

semaphore sem_awrp = new(1);

semaphore sem_rac = new(1); //read address data channel
semaphore sem_rdc = new(1); //read data channel
semaphore sem_radc = new(); //extra read address data channel*/

function new(string name ="slave_driver",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db #(axi_slave_agent_config)::get(this,"","axi_slave_agent_config",slave_agent_cfg))
		`uvm_fatal(get_type_name(), "getting slave cfg in slave driver failed")
endfunction

function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	vif = slave_agent_cfg.vif;
endfunction

task run_phase(uvm_phase phase);
	super.run_phase(phase);
	forever
	begin
		seq_item_port.get_next_item(req);
		drive_to_dut(req);
		seq_item_port.item_done();
		`uvm_info("SLAVE_DRIVER",$sformatf("printing from slave driver \n %s", req.sprint()),UVM_LOW)

	end
endtask

task drive_to_dut(axi_xtn xtn);
xtn = axi_xtn::type_id::create("xtn");



	fork
	//write address channel	
	begin	
		sem_awaddr.get(1);
		slave_awaddr(xtn);
		sem_awaddr.put(1); //after write address channel we have to start data channel so we pass the key
		sem_awad.put(1);
	end
	
	//write data channel
	begin
		sem_awad.get(1);
		sem_awdata.get(1);
		slave_wdata(q1.pop_front());
		sem_awdata.put(1);
		sem_wdrp.put(1);
	end
	
	//response channel
	begin
		sem_wdrp.get(1);
		sem_wrp.get(1);
		slave_wresp(q2.pop_front());
		sem_wrp.put(1);
	end

	//read address channel
	begin
		sem_rac.get(1);
		slave_raddr(xtn);

//		slave_raddr(q3.pop_front());
		sem_rac.put(1);
		sem_radc.put(1);
	end

	//read data channel
	begin	
		sem_radc.get(1);
		sem_rdc.get(1);
		slave_rdata(q3.pop_front());
		sem_rdc.put(1);
	end
	join_any

endtask

task slave_awaddr(axi_xtn xtn);
	$display("Start of slave_awaddr");
	
	repeat($urandom_range(1,5))
	@(vif.slave_drv_cb);

	vif.slave_drv_cb.awready <= 1;
	@(vif.slave_drv_cb);

	wait(vif.slave_drv_cb.awvalid)
//	xtn.aresetn <= vif.slave_drv_cb.aresetn;
	xtn.awid <= vif.slave_drv_cb.awid;
	xtn.awlen <= vif.slave_drv_cb.awlen;
	xtn.awsize <= vif.slave_drv_cb.awsize;
	xtn.awburst <= vif.slave_drv_cb.awburst;
	xtn.awvalid <= vif.slave_drv_cb.awvalid;
	xtn.awaddr <= vif.slave_drv_cb.awaddr;

	q1.push_back(xtn); //write data channel
	q2.push_back(xtn); //write response channel

	vif.slave_drv_cb.awready <= 0;

	repeat($urandom_range(1,5))
	@(vif.slave_drv_cb);

	$display("End of slave_awaddr");
endtask

task slave_wdata(axi_xtn xtn);
	int mem[int];
	$display("Start of slave_wdata");
	xtn.cal_addr();

	$displayh("aligned: %h", xtn.aligned_addr);
	$displayh("addresses calculated in slave driver %p", xtn.addr);
	for(int i = 0; i < (xtn.awlen + 1); i++)
	begin
		vif.slave_drv_cb.wready <= 1;
		@(vif.slave_drv_cb);

		wait(vif.slave_drv_cb.wvalid)
		$display("strobe in slave driver %p", vif.slave_drv_cb.wstrb);
		if( vif.slave_drv_cb.wstrb == 15)
			mem[xtn.addr[i]] =  vif.slave_drv_cb.wdata;

		if( vif.slave_drv_cb.wstrb == 8)
			mem[xtn.addr[i]] =  vif.slave_drv_cb.wdata[31:24];

		if( vif.slave_drv_cb.wstrb == 4)
			mem[xtn.addr[i]] =  vif.slave_drv_cb.wdata[23:16];
	
		if( vif.slave_drv_cb.wstrb == 2)
			mem[xtn.addr[i]] =  vif.slave_drv_cb.wdata[15:8];
		
		if( vif.slave_drv_cb.wstrb == 1)
			mem[xtn.addr[i]] =  vif.slave_drv_cb.wdata[7:0];
		
		if( vif.slave_drv_cb.wstrb == 7)
			mem[xtn.addr[i]] =  vif.slave_drv_cb.wdata[23:0];

		if( vif.slave_drv_cb.wstrb == 14)
			mem[xtn.addr[i]] =  vif.slave_drv_cb.wdata[31:8];

		if( vif.slave_drv_cb.wstrb == 12)
			mem[xtn.addr[i]] =  vif.slave_drv_cb.wdata[31:16];
	
		if( vif.slave_drv_cb.wstrb == 3)
			mem[xtn.addr[i]] =  vif.slave_drv_cb.wdata[15:0];
	
	vif.slave_drv_cb.wready <= 0;

	repeat($urandom_range(1,5))
	@(vif.slave_drv_cb);

	end
	$display("End of drive_wdata");

endtask

task slave_wresp(axi_xtn xtn);
	$display("Start of slave_wresp");
	vif.slave_drv_cb.bvalid <= 1;
	vif.slave_drv_cb.bresp <= 0;
	vif.slave_drv_cb.bid <= xtn.bid;
	@(vif.slave_drv_cb);

	wait(vif.slave_drv_cb.bready)
	vif.slave_drv_cb.bvalid <= 0;
	vif.slave_drv_cb.bresp <= 'hx;

	repeat($urandom_range(1,5))
	@(vif.slave_drv_cb);

	$display("End of slave_wresp");
endtask

task slave_raddr(axi_xtn xtn);
	$display("Start of slave_raddr");

xtn1 = axi_xtn::type_id::create("xtn1");
	repeat($urandom_range(1,5))
	@(vif.slave_drv_cb);

	vif.slave_drv_cb.arready <= 1;
	@(vif.slave_drv_cb);

	wait(vif.slave_drv_cb.arvalid)
	xtn1.arid <= vif.slave_drv_cb.arid;
	xtn1.arlen <= vif.slave_drv_cb.arlen;
	xtn1.arsize <= vif.slave_drv_cb.arsize;
	xtn1.arburst <= vif.slave_drv_cb.arburst;
	vif.slave_drv_cb.arready <= 0;

	q3.push_back(xtn1); //read address channel

	repeat($urandom_range(1,5))
	@(vif.slave_drv_cb);

	$display("End of slave_raddr");
endtask

task slave_rdata(axi_xtn xtn1);
int length = xtn1.arlen;
	$display("Start of slave_rdata");
	for(int i = 0; i < length+1; i++)
		begin
			vif.slave_drv_cb.rdata <= $urandom;
			vif.slave_drv_cb.rvalid <= 1;
			vif.slave_drv_cb.rid <= xtn1.arid;
			vif.slave_drv_cb.rresp <= 0;
		
			if(i == length)
				vif.slave_drv_cb.rlast <= 1;
			else
				vif.slave_drv_cb.rlast <= 0;
		
			@(vif.slave_drv_cb)
			wait(vif.slave_drv_cb.rready)
			vif.slave_drv_cb.rvalid <= 0;
			vif.slave_drv_cb.rlast <= 0;
			vif.slave_drv_cb.rresp <= 'hz;
		end
	$display("End of slave_rdata");
endtask

endclass
