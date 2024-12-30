module diaplay_data #(
parameter NO_SEGMENTS    = 'd8                   					,
parameter NO_LEDS        = 'd10                  					,
parameter NO_DISPLAY     = 'd6                   					,
parameter DATA_WIDTH     = 'd8                   					,
parameter LED_SHIFT      = 'd6                            ,
parameter DISPLAY_SHIFT  = 'd6                            ,
parameter ACC_WIDTH      = 'd10							 
)( 
input                                                clk           ,
input                                                rst_n         ,
input  	          [DATA_WIDTH                 -1:0]  datax0        ,
input  	          [DATA_WIDTH                 -1:0]  datax1        ,
input  	          [DATA_WIDTH                 -1:0]  datay0        ,
input  	          [DATA_WIDTH                 -1:0]  datay1        ,
input                                                start_display ,
output            [ACC_WIDTH                  -1:0]  led           ,
output            [NO_DISPLAY * NO_SEGMENTS   -1:0]  display       ,
output reg signed [ACC_WIDTH                  -1:0]  x_acc         , // value of acceleration on x axis
output reg signed [ACC_WIDTH                  -1:0]  y_acc           // value of acceleration on y axis
);

localparam                    UP            		    = 8'b10011100  ; // circle in the upper side of display
localparam                    DOWN          		    = 8'b10100011  ; // circle in the bottom side of the display
localparam                    POWER_DW      		    = 8'b11111111  ; // all leds shut down 
localparam [NO_DISPLAY  -1:0] INITIAL_VALUE_DISPLAY = 'd1          ; // used for displaying value of acceleration on displays
localparam [NO_LEDS     -1:0] INITIAL_VALUE_LED     = 'd1          ; // used for displaying value of acceleration on leds
																							                       // lowest value of acceleration  - right
                                                                     // highest value of acceleration - left
																			     
wire       [        4   -1:0] value_led         ;                    // gets a value between 0 - 9 to select which led should be on
wire       [        3   -1:0] value_display     ;                    // gets a value between 0 - 5 to select which display should be on
wire       [        3   -1:0] mapped_value      ;
wire       [NO_DISPLAY  -1:0] display_strobe    ;                    // used to select the byte of display that gets the circle

always @(posedge clk)
	if (start_display)	x_acc <= {datax1, datax0[7:6]};
	
always @(posedge clk)
	if (start_display)	y_acc <= {datay1, datay0[7:6]};
	
assign value_led      = (x_acc >> NO_DISPLAY) + (NO_LEDS >> 'd1);	
assign mapped_value   = (x_acc >> (NO_DISPLAY)) + (NO_DISPLAY >> 'd1);
assign value_display  = (mapped_value > (NO_DISPLAY - 'd1)) ? (NO_DISPLAY - 'd1) : mapped_value;
assign led            = INITIAL_VALUE_LED << value_led;
assign display_strobe = (INITIAL_VALUE_DISPLAY << value_display);

genvar i;
generate
	for (i = 0; i < NO_DISPLAY; i = i + 1) begin : bit_extend
		assign display[(i+1)*8-1:i*8] = display_strobe[i] ? (y_acc[9] ? UP : DOWN) : POWER_DW;
	end
 endgenerate

endmodule // display_data