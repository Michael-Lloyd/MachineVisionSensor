`timescale 1ns/1ns

module mipi_csi_rx_byte_aligner #(parameter MIPI_GEAR=16)(
						clk_i,
						reset_i,
						byte_i, //with 16x gering bytes are arrange as [bb,aa]
						byte_o,
						byte_valid_o
						);
						
localparam [7:0]SYNC_BYTE = 8'hB8;		
				
input clk_i;
input reset_i;
input [(MIPI_GEAR-1):0]byte_i;
output reg [(MIPI_GEAR-1):0]byte_o;
output reg byte_valid_o;


reg [3:0]offset;
reg [3:0]sync_offset;
integer i;
reg  [(MIPI_GEAR-1):0] last_byte;
reg  [(MIPI_GEAR-1):0] last_byte_2;
wire [((MIPI_GEAR * 2) - 1):0]word;

reg [(MIPI_GEAR-1):0] output_reg;
reg valid_reg;
reg valid_reg_stage2;
assign word = {last_byte,  last_byte_2};

reg [((MIPI_GEAR * 2) - 1):0]last_word;
reg synced;

always @(negedge clk_i or posedge reset_i)
begin
	if (reset_i)
	begin
		last_byte <= 0;
		last_byte_2<=0;
		last_word <= 0;
		byte_o <= 0;
		byte_valid_o <= 0;
		sync_offset <= 0;
		valid_reg <=0;
	end
	else
	begin
		
		last_byte <= byte_i;
		last_byte_2 <= last_byte;
		last_word <= word;
		
		byte_o <= last_word[sync_offset +:MIPI_GEAR]; // from offset 16bits upwards
		
		byte_valid_o <= valid_reg;
		
		if (synced & !valid_reg)// also check for valid_reg to be intive, this make sure that once sync is detected no further sync are concidered till next reset
		begin
			sync_offset <= offset;
			valid_reg <= 1'h1;
		end
	end
	
end



always @(*)
begin
		offset = 0;
		synced = 0;
	    for (i= (MIPI_GEAR-1) ; i >= 0; i = i - 1) //need to have loop 16 time not 17 because if input bytes are already aligned they will fall on last_byte or byte_i
		begin						   // have to loop downwards
			if ((word[(i ) +: 8] == SYNC_BYTE))
				begin
					synced = 1'b1;
					offset = i[3:0];
				end
		end

end

endmodule
