// Transaction class

class axi_xtn extends uvm_sequence_item;
 `uvm_object_utils(axi_xtn)

	bit aresetn;

	// write address channel
	rand bit [3:0] awid;
	rand bit [7:0] awlen;
	rand bit [31:0] awaddr;
	rand bit [2:0] awsize;
	rand bit [1:0] awburst;
	bit awvalid;
	logic awready;

	// write data channel
	rand bit [3:0] wid;
	rand bit [31:0] wdata[];
	bit [3:0] wstrb[];
	logic wvalid;
	logic wready;
	logic wlast;

	//write response channel
	rand bit [3:0] bid;
	bit [1:0] bresp;
	logic bvalid;
	logic bready;

	//read address channel
	rand bit [3:0] arid;
	rand bit [7:0] arlen;
	rand bit [31:0] araddr;
	rand bit [2:0] arsize;
	rand bit [1:0] arburst;
	bit arvalid;
	logic arready;

	//read data channel
	rand bit [3:0] rid;
	rand bit [31:0] rdata[];
	bit [1:0] rresp[];
	logic rvalid;
	logic rready;
	logic rlast;


	//-----------------------------------//
	bit[31:0] addr[];
	int no_bytes;
	int aligned_addr;
	int start_addr;

	bit[31:0] raddr[];
	int no_rbytes;
	int aligned_raddr;
	int start_raddr;
	//------------------------------------//

	constraint c1 { wdata.size() == (awlen+1); }
	constraint c2 { rdata.size() == (arlen+1); }

	constraint c3 { awburst dist {0 := 10, 1 := 10, 2 := 10}; }
	constraint c4 { arburst dist {0 := 10, 1 := 10, 2 := 10}; }

	constraint c5 { awid == wid; bid == wid; rid == arid; }

	constraint c6 { awsize dist {0 := 10, 1 := 10, 2 := 10}; }
	constraint c7 { arsize dist {0 := 10, 1 := 10, 2 := 10}; }

	constraint c8 { if(awburst == 2)(awlen +1) inside {2,4,8,16}; }
	constraint c9 { if(arburst == 2)(arlen +1) inside {2,4,8,16}; }

	constraint c10 {((awburst == 2'b10 || awburst == 2'b00) && awsize == 1) -> awaddr % 2 == 0;} //alignment for wrap & fixed
	constraint c11 {((awburst == 2'b10 || awburst == 2'b00) && awsize == 2) -> awaddr % 4 == 0;}

	constraint c12 {((arburst == 2'b10 || arburst == 2'b00) && arsize == 1) -> araddr % 2 == 0;} //alignment for wrap & fixed
	constraint c13 {((arburst == 2'b10 || arburst == 2'b00) && arsize == 2) -> araddr % 4 == 0;}

//	constraint c14 {(2 ** awsize) * (awlen + 1) < 4096;}       
//	constraint c15 {(2 ** awsize) * (arlen + 1) < 4096;}
       
	constraint c16 {awlen inside {[1:16]};}      
	constraint c17 {arlen inside {[1:16]};}

	function new(string name = "transaction");
		super.new(name);
	endfunction

	function void post_randomize();
		no_bytes = 2 ** awsize;
		aligned_addr = (int'(awaddr/no_bytes)) * no_bytes;
		start_addr = awaddr;
		wstrb = new[awlen + 1];

		no_rbytes = 2 ** arsize;
		aligned_raddr = (int'(araddr/no_rbytes)) * no_rbytes;
		start_raddr = araddr;
	//	rstrb = new[arlen + 1];
	
          	 cal_addr();
          	 strb_cal();                                                                                      
         	  cal_raddr();
	endfunction

//---------------------------------write operation-----------------------------------//

	function void cal_addr();
		bit wb;
		int burst_len = awlen + 1;
		int N = burst_len; 
		int wrap_boundary = (int'(awaddr/(no_bytes * burst_len))) * (no_bytes * burst_len);
		int addr_n = wrap_boundary + (no_bytes * burst_len);
		addr = new[awlen + 1]; 
		addr[0] = awaddr;

		no_bytes = 2 ** awsize;
		aligned_addr = (int'(awaddr/no_bytes)) * no_bytes;
		start_addr = awaddr;
	
                for(int i=2; i<(burst_len+1); i++)
                   begin
                      if(awburst == 0) //fixed transfer
                           addr[i-1] = awaddr;

                      if(awburst == 1) //increment transfer
                           begin
                               addr[i-1] = aligned_addr + (i-1) * no_bytes;
                           end

                      if(awburst == 2) //wrap transfer
                           begin
                               if(wb == 0)
                                   begin
                                       addr[i-1] = aligned_addr + (i-1) * no_bytes;
                                       if(addr[i-1] == (wrap_boundary + (no_bytes * burst_len)))
                                       begin
                                           addr[i-1] = wrap_boundary;
                                           wb++;
                                       end
                                   end

                               else
                                   addr[i-1] = start_addr + ((i-1) * no_bytes)-(no_bytes * burst_len);
                           end
                  end
	endfunction


	function void strb_cal();
  		int data_bus_bytes = 4;
     	   	int lower_byte_lane, upper_byte_lane;
	
      	 	int lower_byte_lane_0 = start_addr-((int'(start_addr/data_bus_bytes)) * data_bus_bytes);
     		int upper_byte_lane_0 = (aligned_addr + (no_bytes-1)) - ((int'(start_addr/data_bus_bytes)) * data_bus_bytes);
	
      		for(int j = lower_byte_lane_0;j <= upper_byte_lane_0; j++)
       		begin
          		wstrb[0][j] = 1;
        	end


        	for(int i = 1; i < (awlen + 1); i++)
                begin
                	lower_byte_lane=addr[i]-(int'(addr[i]/data_bus_bytes))*data_bus_bytes;
			upper_byte_lane=lower_byte_lane+no_bytes-1;

			for(int j = lower_byte_lane; j <= upper_byte_lane; j++)
                            wstrb[i][j] = 1;
                end
	endfunction

//---------------------------------read operation-----------------------------------//

	function void cal_raddr();
		bit wb;
		int burst_len = arlen + 1;
		int N = burst_len; 
		int wrap_boundary = (int'(araddr/(no_rbytes * burst_len))) * (no_rbytes * burst_len);
		int raddr_n = wrap_boundary + (no_rbytes * burst_len);
		raddr = new[arlen + 1]; 
		raddr[0] = araddr;

		no_rbytes = 2 ** arsize;
		aligned_raddr = (int'(araddr/no_rbytes)) * no_rbytes;
		start_raddr = araddr;

                for(int i=2; i<(burst_len+1); i++)
                   begin
                      if(arburst == 0)
                           raddr[i-1] = araddr;

                      if(arburst == 1)
                           begin
                               raddr[i-1] = aligned_raddr + (i-1) * no_rbytes;
                           end

                      if(arburst == 2)
                           begin
                               if(wb == 0)
                                   begin
                                       raddr[i-1] = aligned_raddr + (i-1) * no_rbytes;
                                       if(raddr[i-1] == (wrap_boundary + (no_rbytes * burst_len)))
                                       begin
                                           raddr[i-1] = wrap_boundary;
                                           wb++;
                                       end
                                   end

                               else
                                   raddr[i-1] = start_raddr + ((i-1) * no_rbytes)-(no_rbytes * burst_len);
                           end
                  end
	endfunction


//---------------------------------Print Method-------------------------------------------//

function void  do_print (uvm_printer printer);
	super.do_print(printer);
                printer.print_field( "aresetn",  this.aresetn,     01,          UVM_DEC);

                //write address channel
                printer.print_field( "awid",  	this.awid,         04,          UVM_DEC);
                printer.print_field( "awaddr",  this.awaddr,       32,          UVM_DEC);
                printer.print_field( "awlen",   this.awlen,        04,          UVM_DEC);
                printer.print_field( "awsize",  this.awsize,       03,          UVM_DEC);
                printer.print_field( "awburst", this.awburst,      02,          UVM_DEC);

                //write data channel
                printer.print_field( "wid",     this.wid,          04,          UVM_DEC);
                foreach(this.wdata[i])
                    begin
                printer.print_field( "wdata",   this.wdata[i],     32,          UVM_BIN);
                printer.print_field( "wstrb",   this.wstrb[i],      4,          UVM_BIN);
                printer.print_field( "wlast",   this.wlast,         1,          UVM_DEC);
                    end

                //Write Response Channel
                printer.print_field( "bid",     this.bid,          04,          UVM_DEC);
                printer.print_field( "bresp",   this.bresp,        02,          UVM_DEC);

                //read address channel
                printer.print_field( "arid",    this.arid,         04,          UVM_DEC);
                printer.print_field( "araddr",  this.araddr,       32,          UVM_DEC);
                printer.print_field( "arlen",   this.arlen,        08,          UVM_DEC);
                printer.print_field( "arsize",  this.arsize,       03,          UVM_DEC);
                printer.print_field( "arburst", this.arburst,      02,          UVM_DEC);

                //read data channel
                printer.print_field( "rid",     this.rid,          04,          UVM_DEC);
                foreach(this.rdata[i])
                    begin
                printer.print_field( "rdata",   this.rdata[i],     32,          UVM_BIN);
                printer.print_field( "rresp",   this.rresp[i],     02,          UVM_DEC);
                    end

	endfunction

//-----------------------------------------Compare Method------------------------------------------------------//

function bit do_compare (uvm_object rhs,uvm_comparer comparer);
     axi_xtn rhs_;
    if(!$cast(rhs_,rhs))
                begin
                 `uvm_fatal("do_compare","failed")
                  return 0;
                end
        return super.do_compare(rhs,comparer) &&
        awid==rhs_.awid  &&
        awaddr==rhs_.awaddr &&
        awlen==rhs_.awlen &&
        awsize==rhs_.awsize &&
        awburst==rhs_.awburst &&

        wid==rhs_.wid &&
        wdata==rhs_.wdata &&
        wstrb==rhs_.wstrb &&
        bid==rhs_.bid &&
        bresp==rhs_.bresp &&

        arid==rhs_.arid  &&
        araddr==rhs_.araddr &&
        arlen==rhs_.arlen &&
        arsize==rhs_.arsize &&
        arburst==rhs_.arburst &&

        rid==rhs_.rid &&
        rdata==rhs_.rdata &&
        rresp==rhs_.rresp;
endfunction

endclass
