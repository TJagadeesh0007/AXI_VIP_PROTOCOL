class axi_scoreboard extends uvm_scoreboard;
`uvm_component_utils(axi_scoreboard)

uvm_tlm_analysis_fifo #(axi_xtn) master_fifoh[];
uvm_tlm_analysis_fifo #(axi_xtn) slave_fifoh[];

axi_env_config env_cfg;
axi_xtn write_xtn, read_xtn;
axi_xtn master_xtn, slave_xtn;

static int packet_rcvd, packet_compared;

//write address covergroup
covergroup write_cg;
	option.per_instance = 1;
	
	awaddr_cp:  coverpoint write_xtn.awaddr {
						bins awaddr_bin = {[0:32'hffff_ffff]};}
	awburst_cp: coverpoint write_xtn.awburst{
						bins awburst_bin[] = {[0:2]};}
	awlen_cp:   coverpoint write_xtn.awlen {
						bins awlen_bin = {[0:15]};}
	awsize_cp:  coverpoint write_xtn.awsize{
						bins awsize_bin[] = {[0:2]};}
	bresp_cp:   coverpoint write_xtn.bresp {
						bins bresp_bin = {0};}

	WRITE_ADDR: cross awburst_cp, awsize_cp, awlen_cp;
endgroup

//write data covergroup
covergroup write_cg1 with function sample(int i);
	option.per_instance = 1;
	
	wdata_cp: coverpoint write_xtn.wdata[i]{
						bins wdata_bin = {[0:32'hffff_ffff]};}

	wstrb_cp: coverpoint write_xtn.wstrb[i]{
						bins wstrobe_bin0 = {4'b1111};
                                                bins wstrobe_bin1 = {4'b1100};
                                                bins wstrobe_bin2 = {4'b0011};
                                                bins wstrobe_bin3 = {4'b1000};
                                                bins wstrobe_bin4 = {4'b0100};
                                                bins wstrobe_bin5 = {4'b0010};
                                                bins wstrobe_bin6 = {4'b0001};
                                                bins wstrobe_bin7 = {4'b1110};}
                                                                
       WRITE_DATA: cross wdata_cp, wstrb_cp;
endgroup

//read address covergroup
covergroup read_cg;
	option.per_instance = 1;
	
	araddr_cp:  coverpoint read_xtn.araddr {
						bins araddr_bin = {[0:32'hffff_ffff]};}
	arburst_cp: coverpoint read_xtn.arburst{
						bins arburst_bin[] = {[0:2]};}
	arlen_cp:   coverpoint read_xtn.arlen {
						bins arlen_bin = {[0:15]};}
	arsize_cp:  coverpoint read_xtn.arsize{
						bins arsize_bin[] = {[0:2]};}

	READ_ADDR: cross arburst_cp, arsize_cp, arlen_cp;
endgroup

//read data covergroup
covergroup read_cg1 with function sample(int i);
	option.per_instance=1;
			
	rdata_cp  :   coverpoint read_xtn.rdata[i]{
						bins rdata_bin={[0:'hffff_ffff]};}
	rresp_cp  :   coverpoint read_xtn.rresp[i]{
						bins rresp_bin={0};}
endgroup

function new(string name = "axi_scoreboard",uvm_component parent);
	super.new(name,parent);
	write_cg = new();
	write_cg1 = new();
	read_cg = new();
	read_cg1 = new();
endfunction

function void build_phase(uvm_phase phase);
	if(!uvm_config_db #(axi_env_config)::get(this,"","axi_env_config",env_cfg))
		`uvm_fatal("AXI_SB", "getting env cfg failed in scoreboard")
	
	master_fifoh = new[env_cfg.no_of_master_agents];
	slave_fifoh = new[env_cfg.no_of_slave_agents];

	foreach(master_fifoh[i])
		master_fifoh[i] = new($sformatf("master_fifoh[%0d]",i),this);

	foreach(slave_fifoh[i])
		slave_fifoh[i] = new($sformatf("slave_fifoh[%0d]",i),this);
	
	super.build_phase(phase);
endfunction
	
task run_phase(uvm_phase phase);
forever
	begin
		
		master_fifoh[0].get(master_xtn);
		packet_rcvd++;
		
		slave_fifoh[0].get(slave_xtn);	
		packet_rcvd++;

			if(master_xtn.compare(slave_xtn))
			begin
				write_xtn = master_xtn;
				read_xtn = master_xtn;
					write_cg.sample();
					packet_compared++;

					read_cg.sample();
					packet_compared++;

					if(master_xtn.wvalid)		
					begin
						foreach(master_xtn.wdata[i])
						begin
							write_cg1.sample(i);
						end
					end

					if(master_xtn.rvalid)		
					begin
						foreach(master_xtn.rdata[i])
						begin
							read_cg1.sample(i);
						end
					end
			end
			else
			    `uvm_error("Scoreboard","Master and Slave packet mismatch");
	end
endtask


function void report_phase(uvm_phase phase);
	`uvm_info("SCOREBOARD",$sformatf("No. of packets received:%0d",packet_rcvd),UVM_LOW);
	`uvm_info("SCOREBOARD",$sformatf("No. of packets compared:%0d",packet_compared),UVM_LOW);
endfunction

endclass
		

