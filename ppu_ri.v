
//
//	fpga_nes/hs/src/ppu/ppu_ri.v
//

module ppu_ri (
	input	wire        clk_in,			// 100MHz system clock signal
	input	wire        rst_in,			// reset signal    
	input	wire [ 2:0] ri_sel_in,		// register interface reg select
	input	wire		ri_ncs_in,		// register interface enable
	input	wire		ri_r_nw_in,		// register interface read/write select
	input	wire [ 7:0] ri_d_in,		// register interface data in
	input	wire		vbl_in,			// VBL (high during vertical blank)
	input	wire		sp_over_in,		// sprite overflow in
	input	wire		sp0_hit_in,		// sprite 0 hit

	input	wire [ 7:0] vram_d_in,
	input	wire [ 7:0] pram_d_in,
	input	wire [ 7:0] oam_d_in,

	output	wire [ 7:0] ri_d_out,		// register interface data out
	output  wire [13:0] vram_a_out, 
	output  reg  [ 7:0] vram_d_out,
	output	reg		    vram_wr_out,	// vram write or read
	output	reg		    pram_wr_out,

	output  wire [ 7:0] oam_a_out,
	output	reg  [ 7:0] oam_d_out,
	output  reg		    oam_wr_out,		// oam write or read
	output	wire		nmi_en_out,		
	output	wire		nt_v_out,
	output	wire		nt_h_out,	
	output	wire		sp_pt_sel_out,	
	output	wire		bg_pt_sel_out,
	output	wire		sp_h_out,
	output	wire		bg_lt_en_out,
	output	wire		sp_lt_en_out,
	output	wire		bg_en_out,
	output	wire		sp_en_out,
	output	wire		cv_out,
	output	wire		fv_out,
	output	wire		ch_out,
	output	wire		fh_out,
	output  wire        vbl_out
);

// ppuctrl   $2000
reg			q_v,		 d_v;
reg			q_h,		 d_h;
reg			q_incre,	 d_incre;
reg			q_sp_pt_sel, d_sp_pt_sel;
reg			q_bg_pt_sel, d_bg_pt_sel;
reg			q_sp_h,		 d_sp_h;
reg			q_nmi_en,	 d_nmi_en;
// ppumask   $2001
reg			q_bg_lt_en,	 d_bg_lt_en;
reg			q_sp_lt_en,	 d_sp_lt_en;
reg			q_bg_en,	 d_bg_en;
reg			q_sp_en,	 d_sp_en;
// ppustatus $2002
reg			q_vbl,		 d_vbl;
// oamaddr   $2003
reg  [ 7:0] q_oam_a,	 d_oam_a;
// oamdata   $2004
reg	 [ 7:0] q_oam_d,	 d_oam_d;
// ppuscroll $2005
reg	 [ 4:0]	q_cv,		 d_cv;
reg	 [ 2:0] q_fv,		 d_fv;
reg	 [ 4:0] q_ch,		 d_ch;
reg  [ 2:0] q_fh,		 d_fh;
// ppuaddr   $2006
reg  [13:0] q_vram_a,    d_vram_a;
// ppudata   $2007
reg	 [ 7:0]	q_vram_d,	 d_vram_d;
//reg	 [ 7:0] q_pram_d,	 d_pram_d;

// internal register
reg			q_wr_tog,	 d_wr_tog;
reg			q_ncs_in,	 d_ncs_in;
reg         q_vbl_in,    d_vbl_in;
reg			q_vram_wr,	 d_vram_wr;
reg			q_oam_wr,	 d_oam_wr;
//reg			q_pram_wr,	 d_pram_wr;
reg	 [13:0]	q_inc_num,	 d_inc_num;

reg  [ 7:0] q_ri_d_out,  d_ri_d_out;

reg  [ 7:0] q_rd_buf,    d_rd_buf;
reg         q_rd_rdy,    d_rd_rdy;

// or negedge rst_in
always @(posedge clk_in) 
	begin
		if(rst_in)
			begin
				q_v			<= 1'h0;
				q_h			<= 1'h0;
				q_incre		<= 1'h0;
				q_sp_pt_sel <= 1'h0;
				q_bg_pt_sel <= 1'h0;
				q_sp_h		<= 1'h0;
				q_nmi_en	<= 1'h0;
				q_bg_lt_en  <= 1'h0;
				q_sp_lt_en  <= 1'h0;
				q_bg_en		<= 1'h0;
				q_sp_en		<= 1'h0;
				q_oam_a		<= 8'h0;
		//		q_oam_d		<= 8'h0;
				q_cv		<= 5'h0;
				q_fv		<= 3'h0;
				q_ch		<= 5'h0;
				q_fh		<= 3'h0;
				q_vram_a	<= 14'h0000;
		//		q_vram_d	<= 8'h00;
				q_wr_tog	<= 1'h0;
				q_ncs_in	<= 1'h1;
		//		q_vram_wr	<= 1'h0;
		//		q_oam_wr	<= 1'h0;
				q_inc_num	<= 14'h0000;
				q_ri_d_out  <= 8'h00;
				q_vbl_in    <= 1'h0;
				q_vbl       <= 1'h0;
				q_rd_buf    <= 8'h00;
				q_rd_rdy    <= 1'h0;
				// todo
			end
		else 
			begin
				q_v			<= d_v;
				q_h			<= d_h;
				q_incre		<= d_incre;
				q_sp_pt_sel	<= d_sp_pt_sel;
				q_bg_pt_sel <= d_bg_pt_sel;
				q_sp_h		<= d_sp_h;
				q_nmi_en	<= d_nmi_en;
				q_bg_lt_en	<= d_bg_lt_en;
				q_sp_lt_en	<= d_sp_lt_en;
				q_bg_en		<= d_bg_en;
				q_sp_en		<= d_sp_en;
				q_oam_a		<= d_oam_a;
		//		q_oam_d		<= d_oam_d;
				q_cv		<= d_cv;
				q_fv		<= d_fv;
				q_ch		<= d_ch;
				q_fh		<= d_fh;
				q_vram_a	<= d_vram_a;
		//		q_vram_d	<= d_vram_d;
				q_wr_tog	<= d_wr_tog;
				q_ncs_in	<= d_ncs_in;
		//		q_vram_wr	<= d_vram_wr;
		//		q_oam_wr	<= d_oam_wr;
				q_inc_num	<= d_inc_num;
				q_ri_d_out  <= d_ri_d_out;
				q_vbl       <= d_vbl;
				q_vbl_in    <= d_vbl_in;
				q_rd_buf    <= d_rd_buf;
				q_rd_rdy    <= d_rd_rdy;
				// todo
			end
	end

always @*
	begin
		d_v			= q_v;
		d_h			= q_h;
		d_incre		= q_incre;
		d_sp_pt_sel = q_sp_pt_sel;
		d_bg_pt_sel = q_bg_pt_sel;
		d_sp_h		= q_sp_h;
		d_nmi_en	= q_nmi_en;
		
		d_bg_lt_en	= q_bg_lt_en;
		d_sp_lt_en	= q_sp_lt_en;
		d_bg_en		= q_bg_en;
		d_sp_en		= q_sp_en;
	//	d_vbl		= q_vbl;
		d_oam_a		= q_oam_a;
		d_oam_d		= 8'h0;
		d_cv		= q_cv;
		d_fv		= q_fv;
		d_ch		= q_ch;
		d_fh		= q_fh;
		d_vram_a	= q_vram_a;
		
		vram_d_out	= 8'h0;
		oam_d_out   = 8'h0;
		vram_wr_out	= 1'h0;
		oam_wr_out	= 1'h0;
		pram_wr_out = 1'h0;
		
		
		d_inc_num	= 14'h0000;
        d_ri_d_out  = 8'h00;
		
		d_rd_buf    = q_rd_rdy ? vram_d_in : q_rd_buf;
		d_rd_rdy    = 1'h0;
		// todo 
		d_vbl_in    = vbl_in;
		d_vbl       = (~q_vbl_in & vbl_in) ? 1'b1 :
		              (~vbl_in)            ? 1'b0 : q_vbl;
		
		d_ncs_in	= ri_ncs_in;
		// todo
		if(q_ncs_in && ~ri_ncs_in) 
			begin
				if(ri_r_nw_in)	// read
					begin
						case(ri_sel_in)
							3'h2: // $2002
								begin
									d_ri_d_out	= {q_vbl, sp0_hit_in, sp_over_in, 5'b00000};
								    d_wr_tog    = 1'b0;
								    d_vbl       = 1'b0;
								end
							3'h4: // $2004
								begin
									d_ri_d_out	= oam_d_in;	
								end
							3'h7: // $2007
								begin
									d_ri_d_out	 = (q_vram_a[13:8] == 6'h3F) ? pram_d_in : q_rd_buf;
									d_rd_rdy     = 1'b1;
									d_inc_num	 = q_incre ? 14'h0020 : 14'h0001;
									d_vram_a     = q_vram_a + (q_incre ? 14'h0020 : 14'h0001);
								end
						endcase
					end
				else			// write
					begin
						case(ri_sel_in)
							3'h0: // $2000
								begin
									d_h			= ri_d_in[0];
									d_v			= ri_d_in[1];
									d_incre		= ri_d_in[2];
									d_sp_pt_sel	= ri_d_in[3];
									d_bg_pt_sel = ri_d_in[4];
									d_sp_h		= ri_d_in[5];
									d_nmi_en	= ri_d_in[7];
								end
							3'h1: // $2001
								begin
									d_bg_lt_en	= ri_d_in[1];
									d_sp_lt_en	= ri_d_in[2];
									d_bg_en		= ri_d_in[3];
									d_sp_en		= ri_d_in[4];
								end
							3'h3: // $2003
								begin
									d_oam_a		= ri_d_in;
								end
							3'h4: // $2004
								begin
									oam_d_out   = ri_d_in;
									oam_wr_out	= 1'b1;
								    d_oam_a     = q_oam_a + 8'h01;
								end
							3'h5: // $2005
								begin
									d_wr_tog	= ~q_wr_tog;
									if(~q_wr_tog)
										begin
											d_ch = ri_d_in[7:3];
											d_fh = ri_d_in[2:0];
										end
									else
										begin
											d_cv = ri_d_in[7:3];
											d_fv = ri_d_in[2:0];
										end
								end
							3'h6: // $2006
								begin
									d_wr_tog	= ~q_wr_tog;
									if(~q_wr_tog)
										begin
											d_vram_a[13:8] = ri_d_in[5:0];
										end
									else
										begin
											d_vram_a[ 7:0] = ri_d_in;
										end
								end
							3'h7: // $2007
								begin
								    if(q_vram_a[ 13:8] == 6'h3F)
										begin
											pram_wr_out	 = 1'b1;
										end
									else
										begin
											vram_wr_out	 = 1'b1;
										end
									vram_d_out	 = ri_d_in;
									d_inc_num	 = q_incre ? 14'h0020 : 14'h0001;
									d_vram_a     = q_vram_a + d_inc_num;
									
								end
						endcase
					end
			end
	end

assign ri_d_out			= (~ri_ncs_in & ri_r_nw_in) ? q_ri_d_out : 8'h00;
assign vram_a_out		= (vram_wr_out || pram_wr_out) ? q_vram_a - q_inc_num : q_vram_a;
//assign vram_d_out		= q_vram_d;
//assign vram_wr_out	= q_vram_wr;
//assign pram_wr_out	= q_pram_wr;
assign oam_a_out		= q_oam_a;
//assign oam_d_out		= q_oam_d;
//assign oam_wr_out		= q_oam_wr;
assign nmi_en_out		= q_nmi_en;
assign nt_v_out			= q_v;
assign nt_h_out			= q_h;
assign sp_pt_sel_out	= q_sp_pt_sel;
assign bg_pt_sel_out	= q_bg_pt_sel;
assign sp_h_out			= q_sp_h;
assign bg_lt_en_out		= q_bg_lt_en;
assign sp_lt_en_out		= q_sp_lt_en;
assign bg_en_out		= q_bg_en;
assign sp_en_out		= q_sp_en;
assign cv_out			= q_cv;
assign fv_out			= q_fv;
assign ch_out			= q_ch;
assign fh_out			= q_fh;
assign vbl_out          = q_vbl;

endmodule
