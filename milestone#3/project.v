module project
	(
		CLOCK,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		  HEX0,
		  HEX1,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		
//		ac97_synch,
//		audio_reset_b,
//		ac97_sdata_out,
//		ac97_sdata_in,
//		ac97_bit_clock,
	);
	input		CLOCK;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	
	output [6:0] HEX0, HEX1;

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
	wire draw;
	wire resetn;
	assign resetn = KEY[0];
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK),
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
		defparam VGA.BACKGROUND_IMAGE = "star.mif";
			
	
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
	 wire [7:0] score;
	 
    combined c1 (
		.clock(CLOCK),
		.resetn(KEY[0]),
		.jump(~KEY[3]),
		.crawl(~KEY[2]),
		.go(~KEY[1]),
		
		.out_x(x),
		.out_y(y),
		.colour(colour),
		.out_plot(writeEn),
		.out_score(score),
	);
//	
//	sfx s0(resetn, CLOCK_50, audio_reset_b, ac97_sdata_out, ac97_sdata_in, ac97_synch, ac97_bit_clock, 2'd1, go);
//	
//	output ac97_synch;
//   output audio_reset_b;
//   output ac97_sdata_out;
//   input ac97_sdata_in;
//   input ac97_bit_clock;
   
   //sfx interface
//   input [1:0] mode; //selects 1 of 4 effects
//   input play; //start playing selected effect
//	
	
	//////////////////////////////////////////////////score display
	hex_decoder h0(score[3:0], HEX0);
	hex_decoder h1(score[7:4], HEX1);
	
endmodule






//module character (clock, resetn, out_x, out_y, colour, plot, jump, crawl);
//module obstacle (clock, resetn, go, out_x, out_y, colour, plot);




module combined(clock, resetn, jump, crawl, go,
						out_x, out_y, colour, out_plot, out_score);
		input clock, resetn, jump, crawl, go;
		output [7:0] out_x;
		output [6:0] out_y; 
		output [2:0] colour;
		output out_plot;
		output [7:0] out_score;

		wire finish, plot;
		wire [7:0] score_display;

		final_data d0(clock, resetn, jump, crawl, go, 
						out_x, out_y, colour, plot, score_display, finish);

		final_control(clock, resetn, finish, plot, score_display, out_score, out_plot);
						
endmodule








module final_data(clock, resetn, jump, crawl, go, 
						out_x, out_y, colour, plot, score_display, finish);
						
		///////////////////////////////////////////////////input				
		input clock, resetn, jump, crawl, go;
		
		//////////////////////////////////////////////////output
		output reg [7:0] out_x;
		output reg [6:0] out_y;
		output reg [2:0] colour;
		output reg plot, finish;
		output reg [7:0] score_display;
		
		///////////////////////////////////////////////////wire
		wire [7:0] character_out_x, obstacle_out_x;
		wire [6:0] character_out_y, obstacle_out_y;
		wire [7:0] score;
		wire character_plot, obstacle_plot;
		wire [2:0] character_colour, obstacle_colour;
		
		
		
//		reg countable;

//		always @(posedge clock)
//		begin 
//			score_display <= score;
//		end
		
		
		

		wire [7:0] ob_x, ch_x;
		wire [6:0] ob_y, ch_y;
		//module character (clock, resetn, out_x, out_y, colour, plot, jump, crawl);
		character c0(clock, resetn, character_out_x, character_out_y, character_colour, character_plot, jump, crawl, ch_x, ch_y);
		
		obstacle b0(clock, resetn, go, obstacle_out_x, obstacle_out_y, obstacle_colour, obstacle_plot, score, ob_x, ob_y);
		
		///////////////////////////////////////////////////counter
		reg [8:0] counter;
		
		always @(posedge clock)
		begin
			if (resetn == 0)
				counter <= 9'b111111111;
			else if (counter == 8'd0)
				counter <= 9'b111111111;
			else
				counter <= counter - 8'd1;		
		end

//		reg counter;
//		
//		always @(posedge clock)
//		begin
//			if (resetn == 0)
//				counter <= 1'd1;
//			else
//				counter <= counter + 1'd1;		
//		end
		
		
		/////////////////////////////////////////////////shifting
		always @(posedge clock)
		begin
			if (resetn == 0) begin
				out_x <= 8'd0;
				out_y <= 7'd0;
				colour <= 3'b111;
				plot <= 1'b0;
				end
			else if (counter < 9'b100000000) begin
				out_x <= character_out_x;
				out_y <= character_out_y;
				colour <= character_colour;
				plot <= character_plot;
				end
			else begin
				out_x <= obstacle_out_x;
				out_y <= obstacle_out_y;
				colour <= obstacle_colour;
				plot <= obstacle_plot;
				end
		end
		
		
		/////////////////////////////////////////////score
		
		always @(posedge clock)
		begin
			if (resetn == 0) begin
				score_display <= 8'd0;
				finish <= 0;
//				out_x <= 8'd0;
//				out_y <= 7'd0;
//				colour <= 3'b111;
//				plot <= 1'b0;
				end
//			if (counter < 9'b100000000) begin
//				out_x <= character_out_x;
//				out_y <= character_out_y;
//				colour <= character_colour;
//				plot <= character_plot;
//				end
//			if (counter >= 9'b100000000) begin
//				out_x <= obstacle_out_x;
//				out_y <= obstacle_out_y;
//				colour <= obstacle_colour;
//				plot <= obstacle_plot;
//				end
//			else if ((ob_x <= 8'd36) && (ob_x >= 8'd10)) begin
////					if (0) begin
//					if (((ch_y + 8'd16) <= ob_y) && (ch_y >= (ob_y + 8'd10)) begin
//						score_display <= score;
//						end
//					else begin
//						score_display <= score_display;
//						finish <= 1;
//						end
//					end
			else if (ob_x == 8'd36) begin
					if (character_out_y == ob_y) begin
						score_display <= score_display;
						finish <= 1;
						end
					else if ((ch_y + 8'd12) == ob_y) begin
						score_display <= score_display;
						finish <= 1;
						end
			end
			else 
				score_display <= score;
		end
		
		
//		reg new_reset;
//		
//		always @(posedge clock)
//		begin
//			if (resetn == 0)
//				new_reset <= 0;
//			else if (game_over)
//				new_reset <= 0;
//			else 
//				new_reset <= resetn;
//		end
		

//		always @(posedge clock)
//		begin
//			if (resetn == 0) begin
//				out_x <= 8'd0;
//				out_y <= 7'd0;
//				colour <= 3'b111;
//				plot <= 1'b0;
//				end
//			else if (counter == 1'd0) begin
//				out_x <= character_out_x;
//				out_y <= character_out_y;
//				colour <= character_colour;
//				plot <= character_plot;
//				end
//			else begin
//				out_x <= obstacle_out_x;
//				out_y <= obstacle_out_y;
//				colour <= obstacle_colour;
//				plot <= obstacle_plot;
//				end
//		end
		
		/////////////////////////////////////////score HEX

		
		
		
endmodule 



module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule 


module final_control(clock, resetn, finish, plot, score_display, out_score, out_plot);
		input clock, resetn, finish, plot;
		input [7:0] score_display;
		output reg [7:0] out_score;
		output reg out_plot;
		
	reg [2:0] current_state, next_state;
		
	localparam Start = 1'd0,
				GAME_OVER = 1'd1;
		
	always @(*)
	begin: state_table
		case (current_state)
//			Start: next_state = GAME_OVER;
			Start: next_state = finish ? GAME_OVER : Start;
			GAME_OVER: next_state = (resetn == 0) ? Start : GAME_OVER;
			default: next_state = Start;
		endcase
	end
	
	
	
	always @(*)
	begin: signals
		out_score = 8'd0;
		out_plot = 1;
		
		case (current_state)
		Start: begin
			out_score = score_display;
			end
			
		GAME_OVER: begin
			out_score = out_score;
			out_plot = 0;
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

						
		
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						

