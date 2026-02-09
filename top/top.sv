module top;
    	import axi_pkg::*;
   
	import uvm_pkg::*;

	bit aclk;  
	always 
		#5 aclk=~aclk;    
		
		axi_if if0(aclk);
	initial 
		begin
			 
			`ifdef VCS
     			 $fsdbDumpvars(0, top);
       			 `endif


			uvm_config_db #(virtual axi_if)::set(null,"*","axi_if",if0);
			
			run_test();
		end   

property AWVALID;
	@(posedge if0.aclk) $rose(if0.awvalid) |-> $stable(if0.awid) && $stable (if0.awlen) && $stable (if0.awburst) && $stable (if0.awsize) && (if0.awaddr) until if0.awready[->1];
endproperty

A1: assert property(AWVALID);
endmodule


