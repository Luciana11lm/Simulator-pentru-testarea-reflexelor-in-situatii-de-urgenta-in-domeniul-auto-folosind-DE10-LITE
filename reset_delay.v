module reset_delay(
input      clk           ,
input      rst_n         ,
output reg rst_delayed_n
);

reg [ 21 -1:0] cnt_dly;

always @(posedge clk or negedge rst_n)
	if (~rst_n)         cnt_dly <= 'd0; else
	if (~cnt_dly[20])   cnt_dly <= cnt_dly + 'd1;
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)		rst_delayed_n <= 'd1; else
						rst_delayed_n <= cnt_dly[20]; 

endmodule // reset_delay