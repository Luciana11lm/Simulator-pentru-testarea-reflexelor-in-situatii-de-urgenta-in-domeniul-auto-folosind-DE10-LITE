module spi_sequencer #(
parameter ACK_DATA_WIDTH = 'd8  ,
parameter REQ_DATA_WIDTH = 'd16 ,
parameter DATA_WIDTH     = 'd8
)(
input                             clk           , // synchronous clock  with frequency of 2MHz
input                             rst_n         , // asynchronous reset
output reg                        host_req      , // host request to get DEVICEID (must stay up until gets an acknowledge - 16Tclk)
output reg [REQ_DATA_WIDTH  -1:0] host_req_data , // data requested
input                             host_ack      , // acknowledge that the request is served
input      [ACK_DATA_WIDTH  -1:0] host_ack_data , // data read from address 0x00
output reg [DATA_WIDTH      -1:0] datax0        , // used to display data read from address 0x00 (first 4 bits)
output reg [DATA_WIDTH      -1:0] datax1        , // used to display data read from address 0x00 (last 4 bits)
output reg [DATA_WIDTH      -1:0] datay0        , // not used
output reg [DATA_WIDTH      -1:0] datay1        , // not used
output                            start_display  
);

//-------------------------------------------------------------------------
//                            INTERNAL WIRES
//-------------------------------------------------------------------------

wire           first_req     ;                     // used to start first request
wire           second_req    ;                     
reg  [32 -1:0] cnt_req       ;                     // counts requests
reg  [2  -1:0] cnt_byte      ;                     // counts which byte of each axis should be read                   
reg  [32 -1:0] cnt_pause     ;                     // counter for pause between two requests - pause 2_000_000 clock cycles

assign first_req     = ((~|cnt_pause) & (~|cnt_req));
assign second_req    = ((~|cnt_pause) & (cnt_req == 'd1));
assign start_display = ((~|cnt_pause) & (cnt_byte == 'd2) & (cnt_req > 'd5));

always @(posedge clk or negedge rst_n)
	if (~rst_n)							 cnt_req <= 'd0; else
	if (host_ack & host_req) cnt_req <= cnt_req + 'd1;

always @(posedge clk or negedge rst_n)
	if (~rst_n)                cnt_pause <= 'd0; else
	if (cnt_pause == 'd20000)  cnt_pause <= 'd0; else
	                           cnt_pause <= cnt_pause + 'd1;
															
always @(posedge clk or negedge rst_n)
	if (~rst_n)							  cnt_byte <= 'd0; else
	if (host_ack & host_req)  cnt_byte <= cnt_byte + 'd1;
		
always @(posedge clk or negedge rst_n)
	if (~rst_n)	              host_req <= 'd0; else
	if (host_ack & host_req)  host_req <= 'd0; else
	if (~|cnt_pause)          host_req <= 'd1;
	
always @(posedge clk)
	if (first_req)  host_req_data <= {2'b00, 6'h2D, 8'h28}; else // write POWER_CTL register for sensor to start reading acceleration
	if (second_req) host_req_data <= {2'b00, 6'h31, 8'h4C}; else // DATA FORMAT for +-2g, full resolution, left justified
	if (~|cnt_pause) begin
		case (cnt_byte)
			'b00:     	 host_req_data <= {2'b10, 6'h34, 8'h00};  // read DATAy0
			'b01:				 host_req_data <= {2'b10, 6'h35, 8'h00};  // read DATAy1
			'b10:     	 host_req_data <= {2'b10, 6'h32, 8'h00};  // read DATAx0
			default:  	 host_req_data <= {2'b10, 6'h33, 8'h00};  // read DATAx1
		endcase
	end

always @(posedge clk)
	if (host_ack & host_req & (cnt_byte == 'd2))	datax0 <= host_ack_data;
	
always @(posedge clk)
	if (host_ack & host_req & (cnt_byte == 'd3))	datax1 <= host_ack_data;
	
always @(posedge clk)
	if (host_ack & host_req & (cnt_byte == 'd0))	datay0 <= host_ack_data;
	
always @(posedge clk)
	if (host_ack & host_req & (cnt_byte == 'd1))	datay1 <= host_ack_data;
	
endmodule // spi_sequencer