`include "top.vh"
`include "uart.vh"

module top_tb;
   
   reg clk_i = 0;
   reg rst_i = 1;
   reg [4:0] rx_i_ctr = 0;
   reg [19:0] rx_tmp = 20'b10100011101010010000;
   reg 	      tmp_rx_bit = 1;
   
   wire [7:0] led_o;
   wire       clk_uart_tx;
   wire       clk_uart_rx, rs232_rx_i;
   
   initial
     begin
	
	$dumpfile("./build/iverilog/chip8.vcd");
	$dumpvars(0,top_tb);
	
	rst_i <= 0;
	
	# 1000 $finish;
	
     end // initial begin

   always #1 clk_i = ~clk_i;
   
   top tb (
	   .ice_clk_i (clk_i),
	   .rstn_i(rst_i),
	   .rs232_rx_i(rs232_rx_i),
	   .led_o (led_o)
	   );
   
   clks #(
	  .PLL_EN(0),
	  .GBUFF_EN(0),
	  .T(`UART_CLK_RX_FREQ / `UART_RX_SAMPLE_RATE / 2)
	  )clk_uart_rx_gen(
			   .clk_i (clk_i),
			   .clk_o (clk_uart_rx)
			   );

   clks #(
	  .PLL_EN(0),
	  .GBUFF_EN(0),
	  .T(`UART_CLK_TX_FREQ / 2)
	  )clk_uart_tx_gen(
			   .clk_i (clk_i),
			   .clk_o (clk_uart_tx)
			   );
   
   
   assign rs232_rx_i =tmp_rx_bit;
   
   always @ (posedge (clk_uart_tx))
     begin
	tmp_rx_bit <=  rst_i ? 1'b1 : rx_tmp[rx_i_ctr];
     end
   
   always @ (posedge clk_uart_tx)
     begin
	if (rx_i_ctr == 19 | rst_i)
	  begin
	     rx_i_ctr <= 0;
	  end
	else
	  begin
	     rx_i_ctr <= rx_i_ctr + 1;
	  end
     end   
   
endmodule // top
