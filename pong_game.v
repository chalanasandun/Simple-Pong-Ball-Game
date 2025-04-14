module pong_game(
    input clk50,
    input btn_left, btn_right,
    output vga_h_sync, vga_v_sync,
    output [2:0] vga_R, vga_G, vga_B,
	 input game_enable
);

reg clk25 = 0;
always @(posedge clk50)
    clk25 <= ~clk25;  // Divide 50MHz to 25MHz

pong pong_inst(
    .clk(clk25),
    .btn_left(btn_left),
    .btn_right(btn_right),
    .vga_h_sync(vga_h_sync),
    .vga_v_sync(vga_v_sync),
    .vga_R(vga_R),
    .vga_G(vga_G),
    .vga_B(vga_B)
);

endmodule