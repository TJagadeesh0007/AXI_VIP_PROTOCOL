//INTERFACE

interface axi_if(input bit aclk);
bit aresetn;

// write address channel
logic [3:0] awid;
logic [7:0] awlen;
logic [31:0] awaddr;
logic [2:0] awsize;
logic [1:0] awburst;
logic awvalid, awready;

// write data channel
logic [3:0] wid;
logic [31:0] wdata;
logic [3:0] wstrb;
logic wvalid, wready, wlast;

//write response channel
logic [1:0] bresp;
logic[3:0] bid;
logic bvalid, bready;

//read address channel
logic [3:0] arid;
logic [7:0] arlen;
logic [31:0] araddr;
logic [2:0] arsize;
logic [1:0] arburst;
logic arvalid, arready;

//read data channel
logic [3:0] rid;
logic [31:0] rdata;
logic [1:0] rresp;
logic rvalid, rready, rlast;

clocking master_drv_cb @(posedge aclk);
	default input #1 output #1;
	output aresetn;
	output awid,awlen,awaddr,awsize,awburst,awvalid; 
	output wid,wdata,wstrb,wvalid,wlast;
	output bready;
	output arvalid,arid,arlen,arsize,araddr,arburst;
	output rready; 
	input wready;
	input bvalid,bresp,bid; 
	input arready;
	input rid,rdata,rvalid,rlast,rresp;
	input awready;
endclocking

clocking master_mon_cb @(posedge aclk);
	default input #1 output #1;
	input aresetn;
	input awid,awlen,awaddr,awsize,awburst,awvalid,awready; 
	input wid,wdata,wstrb,wvalid,wlast,wready;
	input arvalid,arid,arlen,arsize,araddr,arburst,arready;
	input bvalid,bresp,bid,bready; 
	input rid,rdata,rvalid,rlast,rresp,rready;
endclocking

clocking slave_drv_cb @(posedge aclk);
	default input #1 output #1;
	output wready;
	output bvalid,bresp,bid; 
	output arready;
	output rid,rdata,rvalid,rlast,rresp;
	output awready;
	input aresetn;
	input awid,awlen,awaddr,awsize,awburst,awvalid; 
	input wid,wdata,wstrb,wvalid,wlast;
	input bready;
	input arvalid,arid,arlen,arsize,araddr,arburst;
	input rready; 
endclocking

clocking slave_mon_cb @(posedge aclk);
	default input #1 output #1;
	input aresetn;
	input awid,awlen,awaddr,awsize,awburst,awvalid,arready,awready; 
	input wid,wdata,wstrb,wvalid,wlast,wready;
	input arvalid,arid,arlen,arsize,araddr,arburst;
	input bvalid,bresp,bid,bready; 
	input rid,rdata,rvalid,rlast,rresp,rready;
endclocking

modport MASTER_DRV(clocking master_drv_cb);
modport MASTER_MON(clocking master_mon_cb);
modport SLAVE_DRV(clocking slave_drv_cb);
modport SLAVE_MON(clocking slave_mon_cb);




property AWVALID;
	@(posedge aclk) $rose(awvalid) |-> $stable(awid) && $stable (awlen) && $stable (awburst) && $stable (awsize) && (awaddr) until awready[->1];
endproperty
      
property WVALID;
	@(posedge aclk) $rose(wvalid) |-> $stable(wid) && $stable(wdata) && $stable (wstrb) && $stable(wlast) until wready[->1];
endproperty
  
property ARVALID;
	@(posedge aclk) $rose(arvalid) |-> $stable(arid) && $stable (arlen) && $stable (arburst) && $stable (arsize) && (araddr) until arready[->1];
endproperty

property BVALID;
	@(posedge aclk) $rose(bvalid) |-> $stable(bid) && $stable (bresp) until bready[->1];
endproperty
   
property RVALID;
	@(posedge aclk) $rose(rvalid) |-> $stable(rid) && $stable (rdata) && $stable (rlast)  && (rresp) until rready[->1];
endproperty

property AWVALID_AWREADY;
	@(posedge aclk) awvalid && !awready |=> awvalid;
endproperty 
   
property WVALID_WREADY;
	@(posedge aclk) wvalid && !wready |=> wvalid;
endproperty 
   
property ARVALID_ARREADY;
	@(posedge aclk) arvalid && !arready |=> arvalid;
endproperty 

property BVALID_BREADY;
	@(posedge aclk) bvalid && !bready |=> bvalid;
endproperty 

property RVALID_RREADY;
	@(posedge aclk) rvalid && !rready |=> rvalid;
endproperty 

   //wrapping type unaligned address not happen
property R_wrap_type;
	@(posedge aclk) (arburst==2)|->(arsize==1) |-> araddr%2==0;
endproperty

property R_wrap_type1;
	@(posedge aclk)  (arburst==2)|->(arsize==2) |-> araddr%4==0;
endproperty

property W_wrap_type;
	@(posedge aclk)  (awburst==2)|->(awsize==1) |-> awaddr%2==0;
endproperty 

property W_wrap_type1;
 	@(posedge aclk) (awburst==2)|-> (awsize==2) |-> awaddr%4==0;
endproperty

property ar_size;
	@(posedge aclk) awvalid |-> (awsize<3);
endproperty

property aw_size;
	@(posedge aclk) arvalid |-> (arsize<3);
endproperty

property W_burst_type_wrap;
	@(posedge aclk) (awburst==2)|-> ((awlen==1)||(awlen==3)||(awlen==7)||(awlen==15));
endproperty

property R_burst_type_wrap;
 	@(posedge aclk) (arburst==2)|-> ((arlen==1)||(arlen==3)||(arlen==7)||(arlen==15));
endproperty

property WBURST;
	@(posedge aclk) awvalid |-> (awburst!==3);
endproperty

property RBURST;
	@(posedge aclk) arvalid |-> (arburst!==3);
endproperty

property WLAST;
	@(posedge aclk) wlast |-> (wvalid)&&(!wready) |=> wvalid;
endproperty

property RLAST;
	@(posedge aclk) rlast |-> (rvalid)&&(!rready) |=> rvalid;
endproperty


A1: assert property (AWVALID)
	$display("AWVALID successful");
else
	$display("AWVALID not successful");
	
A2: assert property (WVALID)
	$display("WVALID successful");
else
	$display("WVALID not successful");

A3: assert property (ARVALID)
	$display("ARVALID successful");
else
	$display("ARVALID not successful");

A4: assert property (BVALID)
	$display("BVALID successful");
else
	$display("BVALID not successful");

A5: assert property (RVALID)
	$display("RVALID successful");
else
	$display("RVALID not successful");


A6: assert property (AWVALID_AWREADY)
	$display("AWVALID_AWREADY successful");
else
	$display("AWVALID_AWREADY not successful");

A7: assert property (WVALID_WREADY)
	$display("AWVALID successful");
else
	$display("AWVALID not successful");

A8: assert property (ARVALID_ARREADY)
	$display("ARVALID_ARREADY successful");
else
	$display("ARVALID_ARREADY not successful");

A9: assert property (BVALID_BREADY)
	$display("BVALID_BREADY successful");
else
	$display("BVALID_BREADY not successful");

A10: assert property (RVALID_RREADY)
	$display("AWVALID successful");
else
	$display("AWVALID not successful");


B1: assert property (R_wrap_type)
	$display("R_wrap_type successful");
else
	$display("R_wrap_type not successful");

B2: assert property (R_wrap_type1)
	$display("R_wrap_type1 successful");
else
	$display("R_wrap_type1 not successful");

B3: assert property (W_wrap_type)
	$display("W_wrap_type successful");
else
	$display("W_wrap_type not successful");

B4: assert property (W_wrap_type1)
	$display("W_wrap_type1 successful");
else
	$display("W_wrap_type1 not successful");


B5: assert property (ar_size)
	$display("ar_size successful");
else
	$display("ar_size not successful");

B6: assert property (aw_size)
	$display("aw_size successful");
else
	$display("aw_size not successful");


B7: assert property (R_burst_type_wrap)
	$display("R_burst_type_wrap successful");
else
	$display("R_burst_type_wrap not successful");

B8: assert property (W_burst_type_wrap)
	$display("W_burst_type_wrap successful");
else
	$display("W_burst_type_wrap not successful");


B9: assert property (WBURST)
	$display("WBURST successful");
else
	$display("WBURST not successful");

B10: assert property (RBURST)
	$display("RBURST successful");
else
	$display("RBURST not successful");


C1: assert property (WLAST)
	$display("WLAST successful");
else
	$display("WLAST not successful");

C2: assert property (RLAST)
	$display("RLAST successful");
else
	$display("RLAST not successful");


//A21: cover property (VALID);
//A31: cover property (ARVALID);
//A41: cover property (BVALID);
//A51: cover property (RVALID);


	
endinterface


