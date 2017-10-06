module top_tb;
   
   reg clk_i = 0;
   reg rst_i = 1;
   wire [7:0] led_o;
   wire       rs232_tx_o;
   wire       rs232_rx_i = 1'b1;
   
   
   initial
     begin
	
	$dumpfile("./build/iverilog/uart.vcd");
	$dumpvars(0,top_tb);

	# 2000 rst_i <= 0;
	
	# 100000 $finish;
	
     end

   
   always #1 clk_i = ~clk_i;
   
   
   top tb (
	   .ice_clk_i (clk_i),
	   .rstn_i(rst_i),
	   .rs232_rx_i(rs232_rx_i),
	   .led_o (led_o),
	   .rs232_tx_o(rs232_tx_o)
	   );   

endmodule // top

   
   
   
    
