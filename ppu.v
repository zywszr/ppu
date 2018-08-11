
//
// fpga_nes/hs/src/ppu/ppu.v
//

module ppu (
	input	wire        clk_in,			// 100MHz system clock signal
	input	wire        rst_in,			// reset signal
	input	wire [ 2:0] ri_sel_in,	 	// register interface reg select
	input	wire        ri_ncs_in,		// register interface enable
	input	wire        ri_r_nw_in,		// register interface read/write select
	input	wire [ 7:0] ri_d_in,		// register interface data in
	input	wire [ 7:0] vram_d_in,		// video memory data bus (input)
	output	wire        hsync_out,		// vga hsync signal
	output	wire        vsync_out,		// vga vsync signal
	output	wire [ 2:0] r_out,			// vga red signal
	output	wire [ 2:0] g_out,			// vga green signal
	output	wire [ 1:0] b_out,			// vga blue signal
	output	wire [ 7:0] ri_d_out,		// register interface data out
	output	wire        nvbl_out,		// /VBL (low during vertical blank)
	output	wire [13:0] vram_a_out,		// video memory address bus
	output	wire [ 7:0] vram_d_out,		// video memory data bus (output)
	output	wire        vram_wr_out		// video memory read/write select
);

//
// PPU_VGA: VGA output block.
//

wire [ 5:0] vga_sys_palette_idx;
wire [ 9:0] vga_nes_x;
wire [ 9:0] vga_nes_y;
wire [ 9:0] vga_nes_y_next;
wire        vga_pix_pulse;
wire        vga_vblank;

ppu_vga ppu_vga_blk (
	.clk_in(clk_in),
	.rst_in(rst_in),
	.sys_palette_idx_in(vga_sys_palette_idx),
	.hsync_out(hsync_out),
	.vsync_out(vsync_out),
	.r_out(r_out),
	.g_out(g_out),
	.b_out(b_out),
	.nes_x_out(vga_nes_x),
	.nes_y_out(vga_nes_y),
	.nes_y_next_out(vga_nes_y_next),
	.pix_pulse_out(vga_pix_pulse),
	.vblank_out(vga_vblank)
);

//
// PPU_RI: register output block
//

wire [ 7:0] ri_pram_d_in;
//wire [ 7:0] ri_pram_d_out;
wire		ri_pram_wr;
wire [ 7:0] ri_oam_d_in;
wire [ 7:0] ri_oam_a_out;
wire [ 7:0] ri_oam_d_out;
wire		ri_oam_wr_out;
wire		ri_nmi_en;
wire		ri_nt_v;
wire		ri_nt_h;
wire		ri_sp_pt_sel;
wire		ri_bg_pt_sel;
wire		ri_sp_h;
wire		ri_bg_lt_en;
wire		ri_sp_lt_en;
wire		ri_bg_en;
wire		ri_sp_en;
wire [ 4:0] ri_cv;
wire [ 2:0] ri_fv;
wire [ 4:0] ri_ch;
wire [ 2:0] ri_fh;
wire [13:0] ri_vram_a_out;
wire		sp_over;
wire		sp0_hit;	
wire        ri_vbl;

ppu_ri ppu_ri_blk (
	.clk_in(clk_in),
	.rst_in(rst_in),
	.ri_sel_in(ri_sel_in),
	.ri_ncs_in(ri_ncs_in),
	.ri_r_nw_in(ri_r_nw_in),
	.ri_d_in(ri_d_in),
	.vbl_in(vga_vblank),
	.sp_over_in(sp_over),
	.sp0_hit_in(sp0_hit),
	.vram_d_in(vram_d_in),
	.pram_d_in(ri_pram_d_in),
	.oam_d_in(ri_oam_d_in),
	.ri_d_out(ri_d_out),
	.vram_a_out(ri_vram_a_out),
	.vram_d_out(vram_d_out),
	.vram_wr_out(vram_wr_out),
	.pram_wr_out(ri_pram_wr),
	.oam_a_out(ri_oam_a_out),
	.oam_d_out(ri_oam_d_out),
	.oam_wr_out(ri_oam_wr_out),
	.nmi_en_out(ri_nmi_en),
	.nt_v_out(ri_nt_v),
	.nt_h_out(ri_nt_h),
	.sp_pt_sel_out(ri_sp_pt_sel),
	.bg_pt_sel_out(ri_bg_pt_sel),
	.sp_h_out(ri_sp_h),
	.bg_lt_en_out(ri_bg_lt_en),
	.sp_lt_en_out(ri_sp_lt_en),
	.bg_en_out(ri_bg_en),
	.sp_en_out(ri_sp_en),
	.cv_out(ri_cv),
	.fv_out(ri_fv),
	.ch_out(ri_ch),
	.fh_out(ri_fh),
	.vbl_out(ri_vbl)
);

//
// PPU_BG: background output block
//

wire [ 3:0] bg_pl_idx;
wire [13:0] bg_vram_a_out;
wire        bg_vram_wr_out;

ppu_bg ppu_bg_blk (
	.clk_in(clk_in),
	.rst_in(rst_in),
	.bg_en_in(ri_bg_en),
	.bg_lt_en_in(ri_bg_lt_en),
	.bg_pt_sel_in(ri_bg_sel),
	.nt_v_in(ri_nt_v),
	.nt_h_in(ri_nt_h),
	.cv_in(ri_cv),
	.fv_in(ri_fv),
	.ch_in(ri_ch),
	.fh_in(ri_fh),
	.nes_x_in(vga_nes_x),
	.nes_y_in(vga_nes_y),
	.nes_nxt_y_in(vga_nes_y_next),
	.pix_pulse_in(vga_pix_pulse),
	.vram_d_in(vram_d_in),
	.vram_a_out(bg_vram_a_out),
	.vram_wr_out(bg_vram_wr_out),
	.pl_idx_out(bg_pl_idx)
);

assign vram_a_out = bg_vram_wr_out ? bg_vram_a_out : ri_vram_a_out;


ppu_sp ppu_sp_blk (
	.clk_in(clk_in),
	.rst_in(rst_in),
	.sp_over_out(sp_over),
	.sp0_hit_out(sp0_hit)
);

reg  [ 5:0] palette_ram [31:0];

`define PRAM_A(addr) ((addr & 5'h03) ? addr : (addr & 5'h0f))

always @(posedge clk_in)
	begin
		if(rst_in)
			begin
				palette_ram[`PRAM_A(5'h00)] <= 6'h09;
				palette_ram[`PRAM_A(5'h01)] <= 6'h01;
				palette_ram[`PRAM_A(5'h02)] <= 6'h00;
				palette_ram[`PRAM_A(5'h03)] <= 6'h01;
				palette_ram[`PRAM_A(5'h04)] <= 6'h00;
				palette_ram[`PRAM_A(5'h05)] <= 6'h02;
				palette_ram[`PRAM_A(5'h06)] <= 6'h02;
				palette_ram[`PRAM_A(5'h07)] <= 6'h0d;
				palette_ram[`PRAM_A(5'h08)] <= 6'h08;
				palette_ram[`PRAM_A(5'h09)] <= 6'h10;
				palette_ram[`PRAM_A(5'h0a)] <= 6'h08;
				palette_ram[`PRAM_A(5'h0b)] <= 6'h24;
				palette_ram[`PRAM_A(5'h0c)] <= 6'h00;
				palette_ram[`PRAM_A(5'h0d)] <= 6'h00;
			    palette_ram[`PRAM_A(5'h0e)] <= 6'h04;
			    palette_ram[`PRAM_A(5'h0f)] <= 6'h2c;
			    palette_ram[`PRAM_A(5'h11)] <= 6'h01;
			    palette_ram[`PRAM_A(5'h12)] <= 6'h34;
		        palette_ram[`PRAM_A(5'h13)] <= 6'h03;
		        palette_ram[`PRAM_A(5'h15)] <= 6'h04;
		        palette_ram[`PRAM_A(5'h16)] <= 6'h00;
		        palette_ram[`PRAM_A(5'h17)] <= 6'h14;
		        palette_ram[`PRAM_A(5'h19)] <= 6'h3a;
				palette_ram[`PRAM_A(5'h1a)] <= 6'h00;
		        palette_ram[`PRAM_A(5'h1b)] <= 6'h02;
		        palette_ram[`PRAM_A(5'h1d)] <= 6'h20;
				palette_ram[`PRAM_A(5'h1e)] <= 6'h2c;
				palette_ram[`PRAM_A(5'h1f)] <= 6'h08;
			end
		else
			begin
				if (ri_pram_wr)
					begin
						palette_ram[`PRAM_A(vram_a_out[ 4:0])] <= vram_d_out[ 5:0];
					end
			end
	end

assign ri_pram_d_in			= palette_ram[`PRAM_A(vram_a_out[ 4:0])];
// todo

assign vga_sys_palette_idx	= palette_ram[{1'b0, bg_pl_idx}];
assign nvbl_out				= ~(ri_vbl & ri_nmi_en);

endmodule
