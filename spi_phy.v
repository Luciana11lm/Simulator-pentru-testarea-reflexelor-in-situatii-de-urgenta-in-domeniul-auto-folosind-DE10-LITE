module spi_phy #(
parameter ACK_DATA_WIDTH = 'd8  ,
parameter REQ_DATA_WIDTH = 'd16 ,
parameter CNT_WIDTH      = 'd4  
)(
input                         clk           , // synchronous clock with frequency of 2MHz
input                         spi_clk       , // synchronous clock with frequency of 2MHz shifted 190 degrees
input                         rst_n         , // asynchronous reset
input                         host_req      , // host request to get DEVICEID (must stay up until gets an acknowledge - 16Tclk)
input  [REQ_DATA_WIDTH  -1:0] host_req_data , // data requested
output                        host_ack      , // acknowledge that the request is served
output [ACK_DATA_WIDTH  -1:0] host_ack_data , // data read from address 0x00
output                        spi_sclk      , // clock used by the sensor
output reg                    spi_cs_n      , // chip select, active low
output                        spi_sdo       , // not used
inout                         spi_sdio        // data sent by the sensor
);

//-------------------------------------------------------------------------
//                            INTERNAL WIRES
//-------------------------------------------------------------------------

reg 	 [CNT_WIDTH       -1:0] cnt_transfer  ; // counter for every bit transferred
reg 	 [CNT_WIDTH       -1:0] cnt_transfer_d; // counter delayed 
reg    [ACK_DATA_WIDTH  -1:0] ack_data_out  ; // concatenates bits that come from sensor
wire                          rw_mode       ; // takes the R/W bit
                                              //	read  - 1, 
															                //	write - 0
wire                          read_mode     ;
wire                          write_mode    ;
localparam [16 - 1:0] LAST_B = 'd1 << 15    ; // last bit, used to get R/W bit

assign read_mode    = (~spi_cs_n & rw_mode & (cnt_transfer < 'd8));
assign write_mode   = (~spi_cs_n & ~rw_mode);
assign spi_sdo      = 1'h0;
assign spi_sclk     = spi_cs_n ? spi_cs_n : spi_clk;
assign host_ack     = (&cnt_transfer_d) & host_req;
assign rw_mode      = |(host_req_data & LAST_B) ;
assign spi_sdio     = (read_mode	| write_mode) ? (|(host_req_data & (LAST_B >> (cnt_transfer)))) : 'hz; 
assign host_ack_data= (host_req & (&cnt_transfer_d)) ? ack_data_out : 'h0;

always @(posedge clk or negedge rst_n)
	if (~rst_n)	  	cnt_transfer <= 'd0; else
	if (spi_cs_n) 	cnt_transfer <= 'd0; else
						      cnt_transfer <= cnt_transfer + 'd1;	
									
always @(posedge clk or negedge rst_n)
	if (~rst_n)	cnt_transfer_d <= 'd0; else
	            cnt_transfer_d <= cnt_transfer;
								
always @(posedge clk)
	if (~spi_cs_n & (~read_mode | ~write_mode)) ack_data_out <= {ack_data_out[6 : 0], spi_sdio}; else
										                          ack_data_out <= 8'd0;
																				 
always @(posedge clk or negedge rst_n)
  if (~rst_n)					             			        spi_cs_n <= 'd1; else
  if (&cnt_transfer)               					    spi_cs_n <= 'd1; else
  if (host_req & (~|cnt_transfer) & ~host_ack)	spi_cs_n <= 'd0; 
				 
endmodule // spi_phy