
//
// fpga_nes/hs/src/ppu/ppu_bg.v
//

module ppu_bg (
	input	wire		clk_in,			// 100MHz system clock signal
	input	wire		rst_in,			// reset signal
	input	wire		bg_en_in,
	input	wire		bg_lt_en_in,
	input	wire		bg_pt_sel_in,
	input	wire		nt_v_in,
	input	wire		nt_h_in,
	input	wire [ 4:0] cv_in,
	input	wire [ 2:0] fv_in,
	input	wire [ 4:0] ch_in,
	input	wire [ 2:0] fh_in,
	input	wire [ 9:0] nes_x_in,
	input	wire [ 9:0] nes_y_in,
	input	wire [ 9:0] nes_nxt_y_in,
	input	wire		pix_pulse_in,
	input	wire [ 7:0] vram_d_in,
	output	reg  [13:0] vram_a_out,
	output  reg         vram_wr_out,
	output	wire [ 3:0] pl_idx_out
);

reg			q_nt_v,			d_nt_v;
reg			q_nt_h,			d_nt_h;
reg  [ 4:0]	q_cv,			d_cv;
reg	 [ 2:0]	q_fv,			d_fv;
reg	 [ 4:0] q_ch,			d_ch;
reg	 [ 2:0] q_fh,			d_fh;
reg	 [ 7:0] q_tl_idx,		d_tl_idx;
reg	 [15:0]	q_shift16_0,	d_shift16_0;
reg	 [15:0] q_shift16_1,	d_shift16_1;
reg			q_shift8_0,		d_shift8_0;
reg			q_shift8_1,		d_shift8_1;

reg  [ 7:0]	q_nt,			d_nt;
reg	 [ 7:0] q_at,			d_at;
reg  [ 7:0] q_pt0,			d_pt0;
reg	 [ 7:0] q_pt1,  		d_pt1;

always @(posedge clk_in or negedge rst_in)
	begin
		if(rst_in)
			begin
				q_nt_v		<= 1'h0;
				q_nt_h		<= 1'h0;
				q_cv		<= 5'h00;
				q_fv		<= 3'h0;
				q_ch		<= 5'h00;
				q_fh		<= 3'h0;
				q_shift16_0	<= 16'h0000;
				q_shift16_1	<= 16'h0000;
				q_shift8_0	<= 1'h0;
				q_shift8_1	<= 1'h0;
				q_nt		<= 8'h00;
				q_at		<= 8'h00;
				q_pt0		<= 8'h00;
				q_pt1		<= 8'h00;
				// todo
			end
		else
			begin
				q_nt_v		<= d_nt_v;
				q_nt_h		<= d_nt_h;
				q_cv		<= d_cv;
				q_fv		<= d_fv;
				q_ch		<= d_ch;
				q_fh		<= d_fh;
				q_shift16_0	<= d_shift16_0;
				q_shift16_1	<= d_shift16_1;
				q_shift8_0	<= d_shift8_0;
				q_shift8_1	<= d_shift8_1;
				q_nt		<= d_nt;
				q_at		<= d_at;
				q_pt0		<= d_pt0;
				q_pt1		<= d_pt1;
				// todo
			end
	end

reg	 inc_h;
reg	 inc_v;
reg	 upd_frame;

always @*
	begin
		d_nt_v	= q_nt_v;
		d_nt_h	= q_nt_h;
		d_cv	= q_cv;
		d_fv	= q_fv;
		d_ch	= q_ch;
		d_fh	= q_fh;
		// todo
		if(inc_h)
			begin
				d_ch		 = q_ch + 1'h1;
			end
		if(inc_v)
			begin
				{d_cv, d_fv} = {q_cv, q_fv} + 1'h1;
				d_ch		 = ch_in;
				d_fh		 = fh_in;
			end
		if(upd_frame)
			begin
				d_nt_v		 = nt_v_in;
				d_nt_h		 = nt_h_in;
				d_cv		 = cv_in;
				d_fv		 = fv_in;
				d_ch		 = ch_in;
				d_fh		 = fh_in;
			end
	end 

always @*
	begin		
		d_nt		= q_nt;
		d_at		= q_at;
		d_pt0		= q_pt0;
		d_pt1		= q_pt1;
		d_shift16_0 = q_shift16_0;
		d_shift16_1 = q_shift16_1;
		d_shift8_0	= q_shift8_0;
		d_shift8_1	= q_shift8_1;
		
		vram_wr_out = 1'b0;
		inc_v		= 1'b0;
		inc_h		= 1'b0;
		upd_frame	= 1'b0;

		if(bg_en_in && (nes_y_in < 239 || nes_nxt_y_in == 0))
			begin
				if(nes_x_in == 319 && pix_pulse_in && (nes_nxt_y_in != nes_y_in))
					begin
						if(nes_nxt_y_in == 0)
							begin
								upd_frame	= 1'h1;
							end
						else
							begin
								inc_v		= 1'h1;
							end
					end
				if(nes_x_in < 256 || (nes_x_in >= 320 && nes_x_in < 336))
					begin
						if(pix_pulse_in)
							begin
								d_shift16_0 = {1'h0, q_shift16_0[14:0]};
								d_shift16_1 = {1'h0, q_shift16_1[14:0]};
							end	
						if(pix_pulse_in && (nes_x_in[ 2:0] == 3'h7))
							begin
								inc_h		= 1'h1;
								d_shift16_0 = {q_pt0, q_shift16_0[8:1]};
								d_shift16_1 = {q_pt1, q_shift16_1[8:1]};
								d_shift8_0	= q_at[0];
								d_shift8_1	= q_at[1];
							end
						vram_wr_out = 1'h1;
						case(nes_x_in[ 1:0])
							2'h0:
								begin
									vram_a_out	= {2'b10, q_nt_v, q_nt_h, q_cv, q_ch};
									d_nt		= vram_d_in;
								end
							2'h1:
								begin
									vram_a_out	= {2'b10, q_nt_v, q_nt_h, 2'b11, 2'b11, q_cv[ 4:2], q_ch[ 4:2]};
									d_at		= vram_d_in	>> {q_cv[1], q_ch[1], 1'h0};
								end
							2'h2:
								begin
									vram_a_out	= {1'b0, bg_pt_sel_in, q_tl_idx, 1'b0, q_fv};
									d_pt0		= vram_d_in;
								end
							2'h3:
								begin
									vram_a_out	= {1'b0, bg_pt_sel_in, q_tl_idx, 1'b1, q_fv};
									d_pt1		= vram_d_in;
								end
						endcase
					end
			end
		
		
	end

assign	pl_idx_out = (~bg_en_in) ? 4'h0 :
					 ((~bg_lt_en_in) && nes_x_in >= 10'h000 && nes_x_in < 10'h008) ? 4'h0:
						{q_shift8_1, q_shift8_0, q_shift16_1[fh_in], q_shift16_0[fh_in]};


endmodule
