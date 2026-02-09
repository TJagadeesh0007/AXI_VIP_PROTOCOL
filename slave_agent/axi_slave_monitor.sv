// slave monitor

class slave_monitor extends uvm_monitor;
`uvm_component_utils(slave_monitor)

axi_slave_agent_config slave_agent_cfg;  	
virtual axi_if.SLAVE_MON vif;

axi_xtn xtn,xtn1,xtn2,xtn3,xtn4;
axi_xtn q1[$], q2[$];

semaphore sem_wdc = new(1); //write data channel
semaphore sem_wac = new(1); //write address channel
semaphore sem_wrc = new(1); //write response channel
semaphore sem_ewdc = new(); //extra write data channel
semaphore sem_ewac = new(); //extra write address channel

semaphore sem_arc = new(1); //read address data channel
semaphore sem_rdc = new(1); //read data channel
semaphore sem_earc = new(); //extra read address data channel
static int pkt_sent;

uvm_analysis_port #(axi_xtn) slave_mon_ap;

function new(string name ="slave_monitor",uvm_component parent);
	super.new(name,parent);
	slave_mon_ap = new("slave_mon_ap",this);
endfunction

function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db #(axi_slave_agent_config)::get(this,"","axi_slave_agent_config",slave_agent_cfg))
		`uvm_fatal(get_type_name(),"getting slave cfg in slave monitor failed")
endfunction

function void connect_phase(uvm_phase phase);
	super.connect_phase(phase);
	vif = slave_agent_cfg.vif;
endfunction

task run_phase(uvm_phase phase);
	super.run_phase(phase);
	forever
		collect_data();
//		`uvm_info("SLAVE_MONITOR",$sformatf("printing from slave monitor \n %s", req.sprint()),UVM_LOW)
endtask

task collect_data();
	
	fork
	//write address channel	
	begin	
		sem_wac.get(1);
		collect_awaddr();
		sem_ewdc.put(1); //after write address channel we have to start data channel so we pass the key
		sem_wac.put(1);
	end
	
	//write data channel
	begin
		sem_ewdc.get(1);
		sem_wdc.get(1);
		collect_wdata(q1.pop_front());
		sem_wdc.put(1);
		sem_ewac.put(1);
	end
	
	//response channel
	begin
		sem_ewac.get(1);
		sem_wrc.get(1);
		collect_bresp();
		sem_wrc.put(1);
	end

	//read address channel
	begin
		sem_arc.get(1);
		collect_raddr();
		sem_arc.put(1);
		sem_earc.put(1);
	end

	//read data channel
	begin	
		sem_earc.get(1);
		sem_rdc.get(1);
		collect_rdata(q2.pop_front());
		sem_rdc.put(1);
	end
	join_any

endtask

task collect_awaddr();
	xtn = axi_xtn::type_id::create("xtn");
	wait(vif.slave_mon_cb.awvalid === 1 && vif.slave_mon_cb.awready === 1)
		xtn.awvalid = vif.slave_mon_cb.awvalid;
		xtn.awaddr = vif.slave_mon_cb.awaddr;
		xtn.awsize = vif.slave_mon_cb.awsize;
		xtn.awid = vif.slave_mon_cb.awid;
		xtn.awlen = vif.slave_mon_cb.awlen;
		xtn.awburst = vif.slave_mon_cb.awburst;
	q1.push_back(xtn);
//	@(vif.slave_mon_cb);

	slave_mon_ap.write(xtn);
	pkt_sent++;
	`uvm_info("SLAVE_MONITOR",$sformatf("printing from slave monitor collect_awaddr \n %s",xtn.sprint()),UVM_LOW)
//	@(vif.slave_mon_cb);

	@(vif.slave_mon_cb);
endtask

task collect_wdata(axi_xtn xtn);
	xtn1 = axi_xtn::type_id::create("xtn1");
	xtn1 = xtn;
	xtn.cal_addr();
	xtn1.wdata = new [xtn.awlen+1];
	xtn1.wstrb = new [xtn.wdata.size()];

	foreach(xtn1.wdata[i])
	begin
		wait(vif.slave_mon_cb.wvalid === 1 && vif.slave_mon_cb.wready === 1)
		
			xtn1.wstrb[i] = vif.slave_mon_cb.wstrb;

			if(vif.slave_mon_cb.wstrb == 15)
				xtn1.wdata[i] = vif.slave_mon_cb.wdata;

			if(vif.slave_mon_cb.wstrb == 8)
				xtn1.wdata[i] = vif.slave_mon_cb.wdata[31:24];

			if(vif.slave_mon_cb.wstrb == 4)
				xtn1.wdata[i] = vif.slave_mon_cb.wdata[23:16];

			if(vif.slave_mon_cb.wstrb == 2)
				xtn1.wdata[i] = vif.slave_mon_cb.wdata[15:8];

			if(vif.slave_mon_cb.wstrb == 1)
				xtn1.wdata[i] = vif.slave_mon_cb.wdata[7:0];

			if(vif.slave_mon_cb.wstrb == 7)
				xtn1.wdata[i] = vif.slave_mon_cb.wdata[23:0];

			if(vif.slave_mon_cb.wstrb == 14)
				xtn1.wdata[i] = vif.slave_mon_cb.wdata[31:8];

			if(vif.slave_mon_cb.wstrb == 12)
				xtn1.wdata[i] = vif.slave_mon_cb.wdata[31:16];

			if(vif.slave_mon_cb.wstrb == 3)
				xtn1.wdata[i] = vif.slave_mon_cb.wdata[15:0];

		xtn.wid = vif.slave_mon_cb.wid;
		xtn.wlast = vif.slave_mon_cb.wlast;
		xtn.wvalid = vif.slave_mon_cb.wvalid;
	
		@(vif.slave_mon_cb);
	end
	slave_mon_ap.write(xtn1);
	pkt_sent++;
	`uvm_info("SLAVE_MONITOR",$sformatf("printing from slave monitor collect_wdata \n %s",xtn1.sprint()),UVM_LOW)
endtask

task collect_bresp();
	xtn2 = axi_xtn::type_id::create("xtn2");
	wait(vif.slave_mon_cb.bvalid === 1 && vif.slave_mon_cb.bready === 1)
		xtn2.bresp = vif.slave_mon_cb.bresp;
	
	@(vif.slave_mon_cb);
	slave_mon_ap.write(xtn2);
	pkt_sent++;
//	`uvm_info("SLAVE_MONITOR",$sformatf("printing from slave monitor collect_bresp \n %s",xtn2.sprint()),UVM_LOW)

//	@(vif.slave_mon_cb);

endtask

task collect_raddr();
	xtn3 = axi_xtn::type_id::create("xtn3");
	wait(vif.slave_mon_cb.arvalid === 1&& vif.slave_mon_cb.arready === 1)

		xtn.arvalid = vif.slave_mon_cb.arvalid;
		xtn.araddr = vif.slave_mon_cb.araddr;
		xtn.arsize = vif.slave_mon_cb.arsize;
		xtn.arid = vif.slave_mon_cb.arid;
		xtn.arlen = vif.slave_mon_cb.arlen;
		xtn.arburst = vif.slave_mon_cb.arburst;
	q2.push_back(xtn3);	

	@(vif.slave_mon_cb);
	slave_mon_ap.write(xtn3);
	pkt_sent++;
//	`uvm_info("SLAVE_MONITOR",$sformatf("printing from slave monitor collect_raddr \n %s",xtn3.sprint()),UVM_LOW)

endtask

task collect_rdata(axi_xtn xtn);
	xtn4 = axi_xtn::type_id::create("xtn4");
	xtn4 = xtn;
	xtn4.rdata = new[xtn4.arlen+1];

	foreach(xtn4.rdata[i])
	begin
		wait(vif.slave_mon_cb.rvalid === 1 && vif.slave_mon_cb.rready === 1)



		xtn4.rid = vif.slave_mon_cb.rid;
		xtn.rvalid = vif.slave_mon_cb.rvalid;
		xtn.rready = vif.slave_mon_cb.rready;
		xtn.rdata[i] = vif.slave_mon_cb.rdata;
		xtn.rresp[i] = vif.slave_mon_cb.rresp;
	
		if(i == (xtn4.rdata.size-1))
		begin
			xtn4.rlast = vif.slave_mon_cb.rlast;
		end
		
		@(vif.slave_mon_cb);
		slave_mon_ap.write(xtn4);
		pkt_sent++;
		`uvm_info("SLAVE_MONITOR",$sformatf("printing from slave monitor collect_rdata \n %s",xtn4.sprint()),UVM_LOW)
	end
endtask

endclass

