module clk_devider_25MHZ(
input      clk      ,
input      rst_n    ,
output reg clk_25MHz
);

always @(posedge clk or negedge rst_n)
	if (~rst_n)	clk_25MHz <= 'd0; else
			    		clk_25MHz <= ~clk_25MHz;

endmodule