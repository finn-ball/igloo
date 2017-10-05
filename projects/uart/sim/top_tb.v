module top_tb;
   
   reg clk_i = 0;
   wire [7:0] led_o;
   wire       rs232_tx_o;
   
   initial
     begin
	
	$dumpfile("./build/iverilog/uart.vcd");
	$dumpvars(0,top_tb);
	
	# 100000 $finish;
	
     end

   
   always #1 clk_i = ~clk_i;
   
   
   top tb (
	   .ice_clk_i (clk_i),
	   .led_o (led_o),
	   .rs232_tx_o(RS232_TX_o)
	   );
    

endmodule // top

   
   
   
    
