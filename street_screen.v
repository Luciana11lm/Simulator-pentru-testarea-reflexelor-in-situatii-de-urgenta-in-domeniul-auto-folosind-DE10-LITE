module street_screen (
input            		 clk     , // 25MHz
input                clk_slow, // 1Hz
input            		 rst_n   , // asynchronous reset active low
input  [10 -1:0] 		 x_acc   , // acceleration on x axis
input  [10 -1:0] 		 y_acc   , // acceleration on y axis
output           		 o_hsync , // horizontal synchronization signal
output           		 o_vsync , // vertical sychronization signal
output [4 - 1:0] 		 o_red   ,
output [4 - 1:0] 		 o_blue  ,
output [4 - 1:0] 		 o_green ,
output reg           over    , // the game is over after 10 obstacles passed and the score can be displayed
output reg [4 - 1:0] score     // score displayed on HEX0 and HEX1 7 segments displays
);

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

//---------------RGB vaues for each object------------------

localparam [12 - 1:0] RGB_SKY        = 12'h5df;
localparam [12 - 1:0] RGB_GRASS      = 12'h0f0;
localparam [12 - 1:0] RGB_ROAD       = 12'hccb;
localparam [12 - 1:0] RGB_ROAD_LINE  = 12'h985;
localparam [12 - 1:0] RGB_OBSTACLE   = 12'h42D;
localparam [12 - 1:0] RGB_CAR        = 12'hFB2;

//---------------Dimensions for each object--------------------
localparam            OBSTACLE_SPEED = 10     ;
localparam            RAZA           = 20     ;																 
localparam            THIRD_ROAD     = 213;                                       // o treime din zona activa 
localparam            START_ROAD     = H_SYNC + H_BACK + THIRD_ROAD;
localparam            END_ROAD       = H_SYNC + H_BACK + H_ACT - THIRD_ROAD;
localparam            CAR_X          = 470;                                       // initial X position of the car
localparam            CAR_Y          = 490;                                       // left corner Y coordinate of the car
localparam            CAR_DIM        = 20;                                        // car width
localparam            ROAD_LINE_LEFT = 365;                                       // X coordinate of the start of the left road line
localparam            ROAD_LINE_RIGHT= 553;                                       // X coordinate of the start of the right road line
localparam            ROAD_LINE_WIDTH= 10;                                       
localparam            LINE1          = 45;                                        // start of the first line on Y
localparam            LINE2          = 185;                                       // start of the second line on Y
localparam            LINE3          = 335;                                       // start of the third line on Y
localparam            LINE_HEIGHT    = 80;
localparam            MIN_POS        = H_SYNC + H_BACK;                           // minim X coordinate for the car
localparam            MAX_POS        = H_SYNC + H_BACK + H_ACT - CAR_DIM;         // maxim X coordinate for the car
localparam            ACC_INV        = 325;                                       // value added to the acceleration to make it positive

//-----------------VGA control signals----------------------------
reg        [10 - 1:0] counter_x         ; // horizontal counter
reg        [10 - 1:0] counter_y         ; // vertical counter
reg        [4  - 1:0] r_red             ;
reg        [4  - 1:0] r_blue            ;
reg        [4  - 1:0] r_green           ;
reg        [10 - 1:0] frame_cnt         ; // frame counter used to display the obstacle
wire                  visible_area      ;

//-----------------Objects control signals------------------------										  
reg        [10 - 1:0] car_position  		; // horizontal coordinate for the car
reg        [10 - 1:0] obstacle_x    		; // horizontal coordinate for the obstacle
reg        [10 - 1:0] obstacle_y    		; // vertical coordinate for the obstacle
reg        [10 - 1:0] line1_y       		; 
reg        [10 - 1:0] line2_y       		; 
reg        [10 - 1:0] line3_y       		; 
reg        [10 - 1:0] line4_y       		; 
reg        [10 - 1:0] line5_y       		;
reg        [10 - 1:0] line6_y       		; 
reg        [10 - 1:0] line7_y       		;
reg        [9  - 1:0] cnt_obstacle_pos  ; // 9 bits counter for random position of the obstacle
wire                  car_crash     		; // este 1 daca unul din colturile superioare ale masinii se gaseste in interiorul cercului 
reg        [4  - 1:0] cnt_obstacles 		; // la 10 obstacole se termina jocul 
reg                   car_crash_prev		; // Semnal care urmărește coliziunile anterioare
reg                   car_crash_curr		; // Semnal care urmărește coliziunile curente

	
//--------------------VGA controller------------------------

assign visible_area = ((counter_x >= (H_SYNC + H_BACK)) & (counter_x < (H_SYNC + H_BACK + H_ACT))) &
                      ((counter_y >= (V_SYNC + V_BACK)) & (counter_y < (V_SYNC + V_BACK + V_ACT)));

always @(posedge clk or negedge rst_n)
	if (~rst_n)                     counter_x <= 'd0; else
	if (counter_x == H_TOTAL - 'd1) counter_x <= 'd0; else     // horizontal counter including off-screen horizontal 144px => 784px
																  counter_x <= counter_x + 'd1;
												
always @(posedge clk or negedge rst_n)
	if (~rst_n)                       counter_y <= 'd0; else
	if (counter_x == H_TOTAL - 'd1) begin                     // only increment when finishing 800px on horizontal
		if (counter_y == V_TOTAL - 'd1) counter_y <= 'd0; else  // veritical counter, including off_screen vertical 35px => 515px
																		counter_y <= counter_y + 'd1; end
																		
always @(posedge clk or negedge rst_n)
	if (~rst_n)	                                                     frame_cnt <= 'd0; else
	if ((counter_x == H_TOTAL - 'd1) & (counter_y == V_TOTAL - 'd1)) frame_cnt <= frame_cnt + 'd1;
													
assign o_hsync = (counter_x < H_SYNC);
assign o_vsync = (counter_y < V_SYNC);

//---------------------Obstacle position-----------------------
always @(posedge clk or negedge rst_n) 
	if (~rst_n)              				  cnt_obstacle_pos <= START_ROAD + RAZA; else
  if ((cnt_obstacle_pos > (END_ROAD - RAZA)) | (cnt_obstacle_pos < (START_ROAD + RAZA)))	  cnt_obstacle_pos <= START_ROAD + RAZA; else
																  	cnt_obstacle_pos <= cnt_obstacle_pos + OBSTACLE_SPEED;
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)	                                                           obstacle_y <= 'd0; else                        // initial nu avem niciun obstacol pe ecran
	if ((frame_cnt == 'd10) | (obstacle_y == (V_SYNC + V_BACK + V_ACT)))   obstacle_y <= RAZA; else                       // un obstacol apare la inceput dupa 10 frame-uri sau cand ajuge unul la final, apare altul
	if ((counter_x == H_TOTAL - 'd1) & (counter_y == V_TOTAL - 'd1))       obstacle_y <= obstacle_y + OBSTACLE_SPEED;     // dupa fiecare frame obstacolul coboara
	
always @(posedge clk_slow or negedge rst_n) 
	if (~rst_n)                                                            obstacle_x <= 'd0; else                         // initial nu avem niciun obstacol pe ecran
	if (obstacle_y > V_ACT)                                                obstacle_x <= cnt_obstacle_pos; 
	
//-----------------------Car position-----------------------------
always @(posedge clk or negedge rst_n)
	if (~rst_n)						                                           	car_position <= CAR_X; else                          // pozitia initiala a masinii pe x este pe mijlocul drumului
	                                                                  car_position <= -x_acc + ACC_INV + (H_SYNC + H_BACK);// x_acc are valori intre -256 si 256,am adauga valoarea coordonatei de unde incepe sectiunea activa + valoare ca sa trecem la numere pozitive, masina poate ajunge si in afara drumului
	
//------------------------Road lines--------------------------------
always @(posedge clk or negedge rst_n)
	if (~rst_n)	                                                           line1_y <= LINE1; else                       
	if (frame_cnt == 'd10)                                                 line1_y <= LINE1; else                       
	if ((counter_x == H_TOTAL - 'd1) & (counter_y == V_TOTAL - 'd1))       line1_y <= line1_y + OBSTACLE_SPEED; 
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)	                                                           line2_y <= LINE2; else                       
	if (frame_cnt == 'd10)                                                 line2_y <= LINE2; else                       
	if ((counter_x == H_TOTAL - 'd1) & (counter_y == V_TOTAL - 'd1))       line2_y <= line2_y + OBSTACLE_SPEED;
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)	                                                           line3_y <= LINE3; else                       
	if (frame_cnt == 'd10)                                                 line3_y <= LINE3; else                       
	if ((counter_x == H_TOTAL - 'd1) & (counter_y == V_TOTAL - 'd1))       line3_y <= line3_y + OBSTACLE_SPEED;
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)	                                                           line4_y <= LINE2; else                       
	if (line1_y == LINE3)                                                  line4_y <= LINE2; else                       
	if ((counter_x == H_TOTAL - 'd1) & (counter_y == V_TOTAL - 'd1))       line4_y <= line4_y + OBSTACLE_SPEED;
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)	                                                           line5_y <= LINE1; else                       
	if (line1_y == LINE3)                                                  line5_y <= LINE1; else                       
	if ((counter_x == H_TOTAL - 'd1) & (counter_y == V_TOTAL - 'd1))       line5_y <= line5_y + OBSTACLE_SPEED;
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)	                                                           line6_y <= LINE1; else                       
	if (line5_y == LINE3)                                                  line6_y <= LINE1; else                       
	if ((counter_x == H_TOTAL - 'd1) & (counter_y == V_TOTAL - 'd1))       line6_y <= line6_y + OBSTACLE_SPEED;
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)	                                                           line7_y <= LINE2; else                       
	if (line5_y == LINE3)                                                  line7_y <= LINE2; else                       
	if ((counter_x == H_TOTAL - 'd1) & (counter_y == V_TOTAL - 'd1))       line7_y <= line7_y + OBSTACLE_SPEED;
	
//--------------------------VGA display---------------------------------
always @(posedge clk or negedge rst_n)
	if (~rst_n) begin                                                                              r_red   <= 4'b0;
										                                                                             r_green <= 4'b0;
										                                                                             r_blue  <= 4'b0; end else 
  if (~visible_area)                                                                             {r_red, r_green, r_blue} <= 12'h000; else
	if ((cnt_obstacles == 'd10))                                                                   
	begin
        // Desenare cuvânt "STOP"
        if (
						(
            // Litera S
            (((counter_x >= 380) & (counter_x < 420)) & ((counter_y >= 270) & (counter_y < 280))) | // linia de sus
            (((counter_x >= 380) & (counter_x < 390)) & ((counter_y >= 270) & (counter_y < 310))) | // marginea stânga
            (((counter_x >= 380) & (counter_x < 420)) & ((counter_y >= 300) & (counter_y < 310))) | // linia de mijloc
            (((counter_x >= 410) & (counter_x < 420)) & ((counter_y >= 300) & (counter_y < 340))) | // marginea dreapta jos
            (((counter_x >= 380) & (counter_x < 420)) & ((counter_y >= 330) & (counter_y < 340)))   // linia de jos
            ) | (
            // Litera T
            (((counter_x >= 430) & (counter_x < 470)) & ((counter_y >= 270) & (counter_y < 280))) | // linia de sus
            (((counter_x >= 445) & (counter_x < 455)) & ((counter_y >= 270) & (counter_y < 340))) | // bara verticală
            // Litera O
            (((counter_x >= 480) & (counter_x < 520)) & ((counter_y >= 270) & (counter_y < 280))) | // linia de sus
            (((counter_x >= 480) & (counter_x < 490)) & ((counter_y >= 270) & (counter_y < 340))) | // marginea stânga
            (((counter_x >= 510) & (counter_x < 520)) & ((counter_y >= 270) & (counter_y < 340))) | // marginea dreapta
            (((counter_x >= 480) & (counter_x < 520)) & ((counter_y >= 330) & (counter_y < 340)))   // linia de jos
            ) | (
            // Litera P
            (((counter_x >= 530) & (counter_x < 570)) & ((counter_y >= 270) & (counter_y < 280))) | // linia de sus
            (((counter_x >= 530) & (counter_x < 540)) & ((counter_y >= 270) & (counter_y < 340))) | // bara verticală
            (((counter_x >= 560) & (counter_x < 570)) & ((counter_y >= 270) & (counter_y < 310))) | // marginea dreapta sus
            (((counter_x >= 530) & (counter_x < 570)) & ((counter_y >= 300) & (counter_y < 310)))   // linia de mijloc
            )
        )                                                                                        {r_red, r_green, r_blue} <= 12'hf00; else       // culoare stop
                                                                                                 {r_red, r_green, r_blue} <= 12'h000;end else    // fundal negru  
	
	begin
		if ((counter_x <= START_ROAD) | (counter_x >= END_ROAD))                                     {r_red, r_green, r_blue} <= RGB_GRASS; 														              
		if ((counter_x >= START_ROAD) & (counter_x < END_ROAD)) begin                                  
			if ((((counter_x >= ROAD_LINE_LEFT) & (counter_x <= ROAD_LINE_LEFT + ROAD_LINE_WIDTH)) |
					((counter_x >= ROAD_LINE_RIGHT) & (counter_x <= ROAD_LINE_RIGHT + ROAD_LINE_WIDTH))) &
					(((counter_y >= line1_y) & (counter_y <= line1_y + LINE_HEIGHT)) |
					((counter_y >= line2_y) & (counter_y <= line2_y + LINE_HEIGHT)) |
					((counter_y >= line3_y) & (counter_y <= line3_y + LINE_HEIGHT)) |
					((counter_y >= line4_y) & (counter_y <= line4_y + LINE_HEIGHT)) |
					((counter_y >= line5_y) & (counter_y <= line5_y + LINE_HEIGHT)) |
					((counter_y >= line6_y) & (counter_y <= line6_y + LINE_HEIGHT)) |
					((counter_y >= line7_y) & (counter_y <= line7_y + LINE_HEIGHT)) ))                     {r_red, r_green, r_blue} <= RGB_ROAD_LINE; else
																																															   {r_red, r_green, r_blue} <= RGB_ROAD; end
		if (((counter_x - obstacle_x)*(counter_x - obstacle_x) +                                    
				(counter_y - obstacle_y)*(counter_y - obstacle_y)) <= RAZA*RAZA)                         {r_red, r_green, r_blue} <= RGB_OBSTACLE;
		if (((counter_x >= car_position) & (counter_x < car_position + CAR_DIM)) &                      
				((counter_y >= CAR_Y) & (counter_y < (CAR_Y + CAR_DIM))))                                {r_red, r_green, r_blue} <= RGB_CAR; 
	end
assign o_red   = visible_area ? r_red   : 4'h0; 
assign o_blue  = visible_area ? r_blue  : 4'h0; 
assign o_green = visible_area ? r_green : 4'h0; 

//----------------------------Score update--------------------------------
assign car_crash = (((car_position - obstacle_x)*(car_position - obstacle_x) + (CAR_Y - obstacle_y)*(CAR_Y - obstacle_y)) <= RAZA*RAZA) |
									 (((car_position + CAR_DIM - obstacle_x)*(car_position + CAR_DIM - obstacle_x) + (CAR_Y - obstacle_y)*(CAR_Y - obstacle_y)) <= RAZA*RAZA);

always @(posedge clk or negedge rst_n)
	if (~rst_n)	car_crash_curr <= 'd0; else
	            car_crash_curr <= car_crash;
							
always @(posedge clk or negedge rst_n)
	if (~rst_n)	car_crash_prev <= 'd0; else
	            car_crash_prev <= car_crash_curr;

always @(posedge clk_slow or negedge rst_n)
	if (~rst_n)                  cnt_obstacles <= 'd0; else
	if (cnt_obstacles == 'd10)   cnt_obstacles <= cnt_obstacles; else
	if (obstacle_y > V_ACT)      cnt_obstacles <= cnt_obstacles + 'd1;     
	
always @(posedge clk or negedge rst_n)  
	if (~rst_n)                                                        score <= 4'd10; else      // la reset scorul ia valoarea maxima si scade pe masura ce au loc coliziuni 
	if ((~car_crash_prev & car_crash_curr) & (cnt_obstacles != 'd10))  score <= score - 'd1; 
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)                                                       over <= 'd0; else
	if ((~car_crash_prev & car_crash_curr) & (cnt_obstacles != 'd10)) over <= 'd1; 

endmodule // street_screen