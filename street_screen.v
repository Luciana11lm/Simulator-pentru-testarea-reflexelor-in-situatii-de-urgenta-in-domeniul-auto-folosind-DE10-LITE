module street_screen (
input            clk     , // 25MHz
input            rst_n   , // asynchronous reset active low
input  [10 -1:0] x_acc   ,
input  [10 -1:0] y_acc   ,
output           o_hsync , // horizontal synchronization signal
output           o_vsync , // vertical sychronization signal
output [4 - 1:0] o_red   ,
output [4 - 1:0] o_blue  ,
output [4 - 1:0] o_green ,
output [4 - 1:0] score 
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

localparam [12 - 1:0] RGB_SKY       = 12'h5df;
localparam [12 - 1:0] RGB_GRAS      = 12'h6de;
localparam [12 - 1:0] RGB_ROAD      = 12'hccb;
localparam [12 - 1:0] RGB_ROAD_LINE = 12'hFFF;
localparam [12 - 1:0] RGB_OBSTACLE  = 12'hF32;
localparam [12 - 1:0] RGB_CAR       = 12'hFB2;
localparam            OBSTACLE_SPEED= 20     ;
localparam            RAZA          = 20     ;

reg        [10 - 1:0] counter_x     ; // horizontal counter
reg        [10 - 1:0] counter_y     ; // vertical counter
reg        [4  - 1:0] r_red         ;
reg        [4  - 1:0] r_blue        ;
reg        [4  - 1:0] r_green       ;
reg        [10 - 1:0] center_x      ; // coordinates for circle center, initially C(319, 239)
reg        [10 - 1:0] center_y      ;
reg        [10 - 1:0] frame_cnt     ; // frame counter used to display the obstacle
wire                  visible_area  ;
																	  
reg        [11 - 1:0] car_position  ; // Poziția orizontală a mașinii
reg        [11 - 1:0] obstacle_x    ; // Poziția orizontală a obstacolului
reg        [10 - 1:0] obstacle_y    ; // Poziția verticală a obstacolului
//reg        [10 - 1:0] obstacle_speed; // Viteza de deplasare a obstacolului

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
																		
always @(posedge clk or negedge rst_n)
	if (~rst_n)	                                                     frame_cnt <= 'd0; else
	if ((counter_x == H_TOTAL - 'd1) & (counter_y == V_TOTAL - 'd1)) frame_cnt <= frame_cnt + 'd1;
													
assign o_hsync = (counter_x < H_SYNC);
assign o_vsync = (counter_y < V_SYNC);

always @(posedge clk or negedge rst_n)
	if (~rst_n)	                                    obstacle_y <= 'd0; else
	if (frame_cnt == 'd400)                         obstacle_y <= 'd195 + RAZA; else
	if ((frame_cnt > 'd400) & (obstacle_y < 'd783))	obstacle_y <= obstacle_y + OBSTACLE_SPEED;
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)                                     obstacle_x <= 'd0; else
	if (obstacle_y >= 'd783)                        obstacle_x <= ($random % 150) + 'd395;
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)							car_position <= 'd481; else
	                        car_position <= ((x_acc + 'd707) * 'd535)/'d1023;
	
always @(posedge clk or negedge rst_n)
	if (~rst_n) begin                                                               r_red   <= 4'b0;
										                                                              r_green <= 4'b0;
										                                                              r_blue  <= 4'b0; end else 
  if (~visible_area)                                                              {r_red, r_green, r_blue} <= 12'h000; else
  if (((counter_x <= 'd375) | (counter_x >= 'd570)) & (counter_y >= 'd195))       {r_out, g_out, b_out} <= RGB_GRASS; else
  if (((counter_x >= car_position) & (counter_x < car_position + 'd20)) &         
      ((counter_y >= 'd490) & (counter_y < 'd510)))                               {r_red, r_green, r_blue} <= RGB_CAR; else
  if (((counter_x - obstacle_x)*(counter_x - obstacle_x) + 
	     (counter_y - obstacle_y)*(counter_y - obstacle_y)) <= RAZA*RAZA)           {r_red, r_green, r_blue} <= RGB_OBSTACLE; else
  if (((counter_x >= 'd375) & (counter_x < 'd570)) & (counter_y >= 'd195))        {r_red, r_green, r_blue} <= RGB_ROAD; else 
                                                                                  {r_red, r_green, r_blue} <= RGB_SKY; 

// Verificăm coliziunea între mașină și obstacol
always @(posedge clk or negedge rst_n) begin
	if (~rst_n)                                                              score <= 'd10; else
	if (((car_position - obstacle_x)*(car_position - obstacle_x) + 
	     ('d500 - obstacle_y)*('d500 - obstacle_y)) <= RAZA*RAZA)            score <= score - 'd1;

assign o_red   = visible_area ? r_red   : 4'h0; 
assign o_blue  = visible_area ? r_blue  : 4'h0; 
assign o_green = visible_area ? r_green : 4'h0; 

endmodule // bouncing_circle