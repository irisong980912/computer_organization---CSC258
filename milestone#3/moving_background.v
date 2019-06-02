
// milestone#1

module moving_background
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
//	wire ld_x, ld_y, draw;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
	 
	 
    combined c1 (
		.clock(CLOCK_50),
		.resetn(KEY[0]),
		.go(~KEY[1]),
		
		.out_x(x),
		.out_y(y),
		.colour(colour),
		.plot(writeEn)
	);
endmodule



module combined (clock, resetn, go, out_x, out_y, colour, plot);
	input clock, resetn, go;

	output [7:0] out_x;
	output [6:0] out_y;
	output [2:0] colour;
	output plot;
	
	wire  en, en_d, down, left, select_colour, draw, change, finish_erase, back_to_start, colour_black, erase_en, init;
	
	
	// module datapath(colour_black, resetn, clock, draw, erase_en, en_d, left, out_x, out_y, change, colour, finish_erase);
	// Instansiate datapath
	datapath d0(
		.colour_black(colour_black),
		.resetn(resetn),
		.clock(clock),
		.draw(draw),
		.erase_en(erase_en),
		.en_d(en_d),
		.left(left),
		
		.out_x(out_x),
		.out_y(out_y),
		.change(change),
		.colour(colour),
		.finish_erase(finish_erase),
	);

	//	module control(clock, resetn, go, change, finish_erase, en_d, left, draw, plot, colour_black, erase_en);
   // Instansiate FSM control
   control c0(
		.clock(clock),
		.resetn(resetn),
		.go(go),
		.change(change),
		.finish_erase(finish_erase),
		
		.en_d(en_d),
		.left(left),
		.draw(draw),
		.plot(plot),
		.colour_black(colour_black),
		.erase_en(erase_en),
		);
		
	
endmodule






// datapath module
module datapath(colour_black, resetn, clock, draw, init, erase_en, en_d, left, out_x, out_y, change, colour, finish_erase);
	input colour_black;
	input resetn, clock;
	input en_d, left, draw, init, erase_en;
	
	output finish_erase;
	output  [7:0] out_x;
	output  [6:0] out_y;
	output change;
	output reg [2:0] colour;
	
	reg [7:0] x;
	reg [6:0] y; 
	reg [3:0] q, frame;
	reg [19:0] delay;
	wire frame_en;
	
	
	//<<<—————————————————————————————————————————————————————————————————————————————————————————————————————————————————————Draw_State
	// speed counter
	always @(posedge clock)
	begin: delay_counter
		if (!resetn)
			delay <= 20'd833_333;
		if (en_d == 1'b1)
			begin
				if (delay == 0)
					delay <= 20'd833_333;
				else
					delay <= delay - 1'b1;
			end
		else
			delay <= delay;
	end
	
	assign frame_en = (delay == 20'd0) ? 1 : 0;
	
	always @(posedge clock)
	begin: frame_counter
		if (!resetn)
			frame <= 4'b0000;
		if (frame_en == 1'b1)
			begin
				if (frame == 4'd14)
					frame <= 4'd0;
				else
					frame <= frame + 1'b1;
			end
		else
			frame <= frame;
	end
	
	assign change = (frame == 4'd14) ? 1 : 0;
	
	
	// <<< ——————————————————————————————————————————————————————————————————Draw & Erase
	// colour_conveter
	always @(posedge clock)
	begin: color_converter
		if (!resetn)
			colour <= 3'b000;
		if (colour_black)
			colour <= 3'b101;
		else
			colour <= 3'b000;
	end
	
	
	// Draw the 4x4 square
	always @(posedge clock)
	begin: counter
		if (!resetn) begin
			q <= 4'b0000;
			end
		if (draw)
			begin
				if (q == 4'b1111) begin
					q <= 4'd0;
					end
				else begin
					q <= q + 1'b1;
					end
			end
		else
			q <= q;
	end
	
	
	// <<< —————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————Erase_State
	reg [4:0] delay_erase;
	
	always @(posedge clock)
	begin: delay_counter_for_erase
		if (!resetn)
			delay_erase <= 5'd10010;
		if (erase_en == 1'b1)
			begin
				if (delay_erase == 0)
					delay_erase <= 5'd10010;
				else
					delay_erase <= delay_erase - 1'b1;
			end
		else
			delay_erase <= delay_erase;
	end
	
	assign finish_erase = (delay_erase == 5'd0) ? 1 : 0;
	
	
	
	// <<<———————————————————————————————————————————————————————————————————————————————————————————————————————————————————————New_x_y_State
	// moving to the left
	
	wire [3:0] r;
	random m0(clock, resetn, r);
	
	always @(posedge clock)
	begin: x_counter
		if (!resetn)
			x <= 8'd160;
		if (left == 1'b1) begin
			if (x == 8'd0) begin
				x <= 8'd160;
				if (!r[0])
					y <= 7'd54;
				else
					y <= 7'd74;
			end
			else
				x <= x - 1'b1;
		end
		else
			x <= x;
	end
	
	
	// y axis not changing
//	assign y = 7'd54;
//	always @(posedge clock)
//	begin: y_counter
//		if (!resetn)
//			y <= 7'd54;
//		else if (en == 1'b1)
//			begin
//				if (down == 1'b1)
//					y <= y + 1'b1;
//				else
//					y <= y - 1'b1;
//			end
//		else
//			y <= y;
//	end
	
	
	
	
	assign out_x = x + q[1:0];
	assign out_y = y + q[3:2];
endmodule

















// control module
module control(clock, resetn, go, change, finish_erase, en_d, left, draw, plot, colour_black, erase_en);
	input resetn, clock, go, change, finish_erase;
	
	//——————————————————————————————————————————————————————————————————————————————————[][][][][][]
	output reg en_d, left, draw, plot, colour_black, erase_en;

	reg [2:0] current_state, next_state;
	
	localparam Start = 3'd0,
					Draw = 3'd1,
					Erase= 3'd2,
					New_x_y = 3'd3;
					

	always @(*)
	begin: state_table
		case (current_state)
			Start: next_state = go ? Draw : Start;
			Draw: next_state = change ?  Erase : Draw;
			Erase: next_state = finish_erase ? New_x_y : Erase;
			New_x_y: next_state = Draw;
			default: next_state = Start;
		endcase
	end
	
	
	
	always @(*)
	begin: signals
		en_d = 1'b0;
		colour_black = 1'b0;
		erase_en = 1'b0;
		left= 1'b0; 
		draw = 1'b0;
		plot = 1'b0;
		
		case (current_state)
		Start: begin
			en_d = 1'b0; // <<<————————————————————————————————————————————————————————————————————————————————————new change
			end
		Draw: begin
			en_d = 1'b1; // <<<————————————————————————————————————————————————————————————————————————————————————new change
			draw = 1'b1;
			colour_black = 1'b1;
			plot = 1'b1;
			end
		Erase: begin
			erase_en = 1'd1;
			draw = 1'b1;
			plot = 1'b1;
			end
		New_x_y : begin
			left = 1'b1;
			end
		endcase
	end
	
	
	
	
	// change state
	always@(posedge clock)
		 begin: state_FFs
			  if(!resetn)
					current_state <= Start;
			  else
					current_state <= next_state;
		 end // state_FFS
endmodule 








// random generator

module rand_0(clk,reset_n,data_in,q);
		input clk, reset_n, data_in;
		output reg q;
		always@(posedge clk)
		   begin
			if(reset_n == 0) 
				  q <= 1'b0; 
			else
				  q<= data_in;
			end
endmodule

module rand_1(clk,reset_n,data_in,q);
		input clk, reset_n ,data_in;
		output reg q;
		always@(posedge clk)
		   begin
			if(reset_n == 0) 
				  q <= 1'b1; 
			else
				  q<= data_in;
			end
endmodule


module random(clk ,reset_n, q);
		input clk, reset_n;
		output [3:0] q;
		
		rand_0 o1(clk, reset_n, q[2] ^ q[3], q[0]);
		rand_1 o2(clk, reset_n, q[0], q[1]);
		rand_1 o3(clk, reset_n, q[1], q[2]);
		rand_1 o4(clk, reset_n, q[2], q[3]);
endmodule
