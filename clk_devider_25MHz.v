module clk_devider_25MHZ(
input      clk      ,
input      rst_n    ,
output reg clk_25MHz,
output reg clk_slow
);

reg [ 32 - 1 : 0] cnt_25k;

always @(posedge clk or negedge rst_n)
	if (~rst_n)	                  cnt_25k <= 'd0; else
	if (cnt_25k == 'd25_000_000)	cnt_25k <= 'd0; else
	                              cnt_25k <= cnt_25k + 'd1;

always @(posedge clk or negedge rst_n)
	if (~rst_n)	   clk_25MHz <= 'd0; else
			    		   clk_25MHz <= ~clk_25MHz;
						
always @(posedge clk or negedge rst_n)
	if (~rst_n)	    clk_slow <= 'd0; else
	if (~|clk_slow) clk_slow <= ~clk_slow;

endmodule //clk_devider_25MHZ