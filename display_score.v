module display_score #(
parameter NO_SEGMENTS = 8
)(
input                             clk           , // 2MHZ
input                             rst_n         ,
input      [ 4           - 1 : 0] score         ,
input                             over          , 
output reg [ NO_SEGMENTS - 1 : 0] display0      ,
output reg [ NO_SEGMENTS - 1 : 0] display1
);

localparam ZERO  = 8'b11000000;
localparam ONE   = 8'b11111001;
localparam TWO   = 8'b10100100;
localparam THREE = 8'b10110000;
localparam FOUR  = 8'b10011001;
localparam FIVE  = 8'b10010010;
localparam SIX   = 8'b10000010;
localparam SEVEN = 8'b11111000;
localparam EIGHT = 8'b10000000;
localparam NINE  = 8'b10010000;
localparam OFF   = 8'b11111111;

always @(posedge clk or negedge rst_n)
	if (~rst_n)	  display0 <= ZERO; else
	if (over) begin
		case(score)
			4'd1 :    display0 <= ONE;
			4'd2 :    display0 <= TWO;
			4'd3 :    display0 <= THREE;
			4'd4 :    display0 <= FOUR;
			4'd5 :    display0 <= FIVE;
			4'd6 :    display0 <= SIX;
			4'd7 :    display0 <= SEVEN;
			4'd8 :    display0 <= EIGHT;
			4'd9 :    display0 <= NINE;
			default:  display0 <= ZERO;
		endcase
	end
	
always @(posedge clk or negedge rst_n)
	if (~rst_n)	    display1 <= ONE; else
	if (over) begin
		case(score)
			4'd10 :     display1 <= ONE;
			default:    display1 <= ZERO;
		endcase
	end

endmodule // display_score