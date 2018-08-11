
//
// fpga_nes/hs/src/ppu/ppu_sp.v
//

module ppu_sp (
	input	wire		clk_in,
	input	wire		rst_in,
	output	wire		sp_over_out,
	output	wire		sp0_hit_out
);

reg  q_sp_over, d_sp_over;
reg  q_sp0_hit, d_sp0_hit;

always @(posedge clk_in)
    begin
        if(rst_in)
            begin
                q_sp_over <= 1'h0;
                q_sp0_hit <= 1'h0;
            end
        else
            begin
                q_sp_over <= d_sp_over;
                q_sp0_hit <= d_sp0_hit;
            end
    end

assign sp_over_out = q_sp_over;
assign sp0_hit_out = q_sp0_hit;

endmodule
