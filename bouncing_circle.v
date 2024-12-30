module bouncing_circle (
input            clk     , // 25MHz
input            rst_n   , // asynchronous reset active low
input  [10 -1:0] x_acc   ,
input  [10 -1:0] y_acc   ,
output           o_hsync , // horizontal synchronization signal
output           o_vsync , // vertical sychronization signal
output [4 - 1:0] o_red   ,
output [4 - 1:0] o_blue  ,
output [4 - 1:0] o_green 
);

localparam RAZA = 'd50;
// Timing constants for 640x480 @ 60 Hz
localparam H_TOTAL = 800;
localparam H_SYNC  = 96;
localparam H_BACK  = 48;
localparam H_ACT   = 640;
localparam H_FRONT = 16;

localparam V_TOTAL = 525;
localparam V_SYNC  = 2;
localparam V_BACK  = 33;
localparam V_ACT   = 480;
localparam V_FRONT = 10;

reg [10 - 1:0] counter_x    ; // horizontal counter
reg [10 - 1:0] counter_y    ; // vertical counter
reg [4  - 1:0] r_red        ;
reg [4  - 1:0] r_blue       ;
reg [4  - 1:0] r_green      ;
reg [10 - 1:0] center_x     ; // coordinates for circle center, initially C(319, 239)
reg [10 - 1:0] center_y     ;
wire           visible_area ;

assign visible_area = ((counter_x >= (H_SYNC + H_BACK)) & (counter_x < (H_SYNC + H_BACK + H_ACT))) &
                      ((counter_y >= (V_SYNC + V_BACK)) & (counter_y < (V_SYNC + V_BACK + V_ACT)));

always @(posedge clk or negedge rst_n)
	if (~rst_n)                     counter_x <= 'd0; else
	if (counter_x == H_TOTAL - 'd1) counter_x <= 'd0; else     // horizontal counter including off-screen horizontal 160px => 800px
																  counter_x <= counter_x + 'd1;
												
always @(posedge clk or negedge rst_n)
	if (~rst_n)                       counter_y <= 'd0; else
	if (counter_x == H_TOTAL - 'd1) begin                     // only increment when finishing 800px on horizontal
		if (counter_y == V_TOTAL - 'd1) counter_y <= 'd0; else  // veritical counter, including off_screen vertical 45px => 525px
																		counter_y <= counter_y + 'd1; end
													
assign o_hsync = (counter_x < H_SYNC);
assign o_vsync = (counter_y < V_SYNC);

always @(posedge clk or negedge rst_n)
	if (~rst_n)	center_x <= 'd319; else
					    center_x <= ((x_acc + 'd707) * 'd535)/'d1023;// ((x_acc + 'd806) * 'd339)/'d1023;
							
always @(posedge clk or negedge rst_n)
	if (~rst_n)	center_y <= 'd239; else
					    center_y <= ((y_acc + 'd597) * 'd375)/'d1023;
	
// circle pattern - center C(319, 239), R = 50px
always @(*) begin
	if (((counter_x - center_x)*(counter_x - center_x) + (counter_y - center_y)*(counter_y - center_y)) <= RAZA*RAZA) begin
		if ((counter_x > 'd144) & (counter_x < 'd230)) begin  
				r_red   <= 8'h45;
				r_blue  <= 8'h09;
				r_green <= 8'h20;	end else
		if ((counter_x > 'd230) & (counter_x < 'd319)) begin
				r_red   <= 8'ha5;
				r_blue  <= 8'h38;
				r_green <= 8'h60;	end else
		if ((counter_x > 'd319) & (counter_x < 'd406)) begin
				r_red   <= 8'hda;
				r_blue  <= 8'h62;
				r_green <= 8'h7d;	end else
		if (counter_x > 'd406) begin
				r_red   <= 8'hff;
				r_blue  <= 8'h5a;
				r_green <= 8'hab;	end
	end else
	begin	r_red   <= 8'hff; //background
				r_blue  <= 8'hff;
				r_green <= 8'hff; end
	end

assign o_red   = visible_area ? r_red   : 4'h0; 
assign o_blue  = visible_area ? r_blue  : 4'h0; 
assign o_green = visible_area ? r_green : 4'h0; 

endmodule // bouncing_circle