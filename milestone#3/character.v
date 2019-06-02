//
module character (clock, resetn, out_x, out_y, colour, plot, jump, crawl, x, y);
	input clock, resetn, jump, crawl;

	output [7:0] out_x;
	output [6:0] out_y;
	output [7:0] x;
	output [6:0] y;
	output [2:0] colour;
	output plot;
	
	// module datapath(colour_black, 
//				resetn, clock, draw, erase_en, 
//				out_x, out_y, colour, 
//				finish_erase, jump_en, crawl_en, Draw_jump_delay, jump_count);
	// Instansiate datapath
	
//	wire draw, finish_erase, colour_black, erase_en, crawl_en, jump_en, Draw_jump_delay, jump_count, 
//	init, change_dir, reach_top, reach_ground;
	wire finish_erase, jump_change_en, finish_jump,
			draw, jumping, colour_black, erase_en, crawl_en, jump_en, init;
	
	
//	module datapath(clock, resetn, draw, jumping, colour_black, erase_en, crawl_en, jump_en, init, 
//																						out_x, out_y, colour, finish_erase, jump_change_en, finish_jump);

	datapath1 d0(		
		.clock(clock),
		.resetn(resetn),
		.draw(draw),
		.jumping(jumping),
		.colour_black(colour_black),
		.erase_en(erase_en),
		.crawl_en(crawl_en),
		.jump_en(jump_en),
		.init(init),
		
		.out_x(out_x),
		.out_y(out_y),
		.colour(colour),
		.finish_erase(finish_erase),
		.jump_change_en(jump_change_en),
		.finish_jump(finish_jump),
		.x(x),
		.y(y),
	);
//module control(clock, resetn, press_crawl, press_jump, finish_erase, finish_jump, jump_change_en, 
//					draw, plot, jumping, colour_black, erase_en, crawl_en, jump_en, init);
	
   control1 c0(
		.clock(clock),
		.resetn(resetn),
		.press_jump(jump),
		.press_crawl(crawl),
		.finish_erase(finish_erase),
		.finish_jump(finish_jump),
		.jump_change_en(jump_change_en),
		
		.draw(draw),
		.plot(plot),
		.jumping(jumping),
		.colour_black(colour_black),
		.erase_en(erase_en),
		.crawl_en(crawl_en),
		.jump_en(jump_en),
		.init(init),
		);
		
endmodule


					


// datapath module
module datapath1(clock, resetn, draw, jumping, colour_black, erase_en, crawl_en, jump_en, init, 
																						out_x, out_y, colour, finish_erase, jump_change_en, finish_jump, x, y);
				
	input clock, resetn, draw, jumping, colour_black, erase_en, crawl_en, jump_en, init;
	
	output finish_erase, jump_change_en;
	output reg [7:0] out_x, x;
	output reg [6:0] out_y, y;
	output reg [2:0] colour;
	output reg finish_jump;
	
//	reg [7:0] x;
//	reg [6:0] y; 
	reg [7:0] q;
	//<<<—————————————————————————————————————————————————————————————————————————————————————————————————————————————————————Jumping Draw State
	// jump speed counter
	reg [27:0] Draw_jump_delay;
	always @(posedge clock)
	begin
		if (resetn == 1'b0)
			Draw_jump_delay <= 28'd250000;
		else if (jumping == 1'b1)
			begin
				if (Draw_jump_delay == 28'b0)
					Draw_jump_delay <= 28'd250000;
				else
					Draw_jump_delay <= Draw_jump_delay - 1'b1;
			end
	end
	assign jump_change_en = (Draw_jump_delay == 28'd0) ? 1 : 0;
	
	
	
//	always @(posedge clock, negedge resetn)
//	begin
//		if (resetn == 1'b0)
//			delay <= 19'd333332;
//		else if (colour_black == 1'b1)
//			begin
//				if (delay == 0)
//					delay <= 19'd333332;
//				else
//					delay <= delay - 1'b1;
//			end
//	end
//
//	
//	assign change_en = (delay == 26'd0) ? 1 : 0;
	

	
	// <<< —————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————Erase_State
	reg [8:0] delay_erase;
	
	always @(posedge clock)
	begin: delay_counter_for_erase
		if (!resetn)
			delay_erase <= 9'b111111111;
		if (erase_en == 1'b1)
			begin
				if (delay_erase == 1'b0)
					delay_erase <= 9'b111111111;
				else
					delay_erase <= delay_erase - 1'b1;
			end
		else
			delay_erase <= delay_erase;
	end
	
	assign finish_erase = (delay_erase == 9'd0) ? 1 : 0;
	
//	
//   reg [4:0] delay_erase;
//	
//	always @(posedge clock)
//	begin: delay_counter_for_erase
//		if (!resetn)
//			delay_erase <= 5'b11111;
//		if (erase_en == 1'b1)
//			begin
//				if (delay_erase == 0)
//					delay_erase <= 5'b11111;
//				else
//					delay_erase <= delay_erase - 1'b1;
//			end
//		else
//			delay_erase <= delay_erase;
//	end
//	
//	assign finish_erase = (delay_erase == 5'd0) ? 1 : 0;
	
	
	// ——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————New_x_y_State
	// ----------------------------------------------------jump, change pixel
	reg reach_top;
	always @(posedge clock)
	begin: jump_counter
		if (!resetn || init) begin
			y <= 7'd75;
			x <= 8'd20;
			reach_top = 1'b0;
			finish_jump <= 1'b0;
		end
	   else if (jump_en == 1'd1) begin
			if (!reach_top) begin// move up
				y <= y - 7'd1; // move up by 1 bit
				x <= x;
				if (y == 7'd45) // reach the top
					reach_top <= 1'b1;
				end
			else if (reach_top) begin // jump to the top and then decrease 
				y <= y + 7'd1; // move down by 1 bit
				x <= x;
				if (y == 7'd75) begin// reach the top
					reach_top <= 1'b0;
					finish_jump <= 1'b1;
					end
				end
			end
		else begin
			y <= y;
		   x <= x;
			reach_top <= reach_top;
			finish_jump <= finish_jump;
		end		
	end

	
	
	
	
//	reg [7:0] count_x;
//	reg [6:0] count_y;
//	
//	// -----Draw the targeting object
//	always @(posedge clock)
//	begin: counter
//		if (!resetn) begin
//			count_x <= 8'd0;
//			count_y <= 7'd0;
//		end
//		if (draw) begin
//			if (count_x == 8'd29) begin
//				count_x <= 8'd0;
//				if (count_y == 7'd29)
//					count_y <= 7'd0;
//				else
//					count_y <= count_y + 7'd1;
//				end
//			else
//				count_x <= count_x + 8'b1;
//				count_y <= count_y;
//		end
//		else
//			count_x <= count_x;
//			count_y <= count_y;
//	end
//	
//	reg [7:0] count_crawl_x;
//	reg [6:0] count_crawl_y;
//	
//	
//	
//	
//	// -----Draw the targeting object
//	always @(posedge clock)
//	begin: counter_crawl
//		if (!resetn) begin
//			count_crawl_x <= 8'd0;
//			count_crawl_y <= 7'd0;
//		end
//		else if (draw) begin
//			if (count_crawl_x == 8'd39) begin
//				count_crawl_x <= 8'd0;
//				if (count_crawl_y == 7'd9)
//					count_crawl_y <= 7'd0;
//				else
//					count_crawl_y <= count_crawl_y + 7'd1;
//			end
//			else begin
//				count_crawl_x <= count_crawl_x + 8'b1;
//				count_crawl_y <= count_crawl_y;
//			end
//		end
//		else begin
//			count_crawl_x <= count_crawl_x;
//			count_crawl_y <= count_crawl_y;
//		end
//	end
//	
//	
//	
//	// -------assign crawling
//	always @(posedge clock)
//	begin: crawl_counter
//	if (crawl_en) begin
//		out_x <= x + count_crawl_x[7:0];
//		out_y <= y + 7'd20 + count_crawl_y[6:0];
//		end
//		
//	else if (init == 1'd1) begin
//		out_x <= 8'd20 + count_x[7:0];
//		out_y <= 7'd75 + count_y[6:0];
//		end
//		
//	else begin 
//		out_x <= x + count_x[7:0];
//		out_y <= y + count_y[6:0];
//		end
//	end



// -----Draw the targeting object
	always @(posedge clock)
	begin: counter
		if (!resetn) begin
			q <= 8'd0;
		end
		if (draw) begin
			if (q == 8'b11111111)
				q <= 8'd0;
			else
				q <= q + 8'd1;
		end
		else
			q <= q;
	end
	
		// <<< ——————————————————————————————————————————————————————————————————Draw & Erase
	// colour_conveter
	always @(posedge clock)
	begin: color_converter
		if (!resetn)
			colour <= 3'b000;
		if (colour_black) begin // not erase
			////////////////////////////////////////////////not crawl
			if (!crawl_en) begin
				if ((q[7:4] == 4'd0) || (q[7:4] == 4'b1111) || (q[3:0] == 4'd0) || (q[3:0] == 4'b1111) || (q == 8'b00111001) || (q == 8'b00111010) || (q == 8'b01001001) || (q == 8'b01001010)) begin
//					if (q == 8'b01001010)
//						colour <= 3'b111;
//					else
					   colour <= 3'b101;
				end
				//////////////////////////////////////////////////////////////////////////////////////////mouth
				else if ((q[7:4] >= 4'b0111) && (q[7:4] <= 4'b1011) && (q[3:0] >= 4'b1001)) begin
					////////////////////////////////////////////////////////////////teeth
					if ((q == 8'b01111011) || (q == 8'b01111101))
						colour <= 3'b111;
					else 
						colour <= 3'b000;
				end
				else 
					colour <= 3'b110;
			end
			///////////////////////////////////////////////crawl
			else begin
				if ((q[7:5] == 3'd0) || (q[7:5] == 3'b111) || (q[4:0] == 5'd0) || (q[4:0] == 5'b11111) || (q == 8'b01011000) || (q == 8'b01011001) || (q == 8'b01111000) || (q == 8'b01111001))
					colour <= 3'b101;
				else 
					colour <= 3'b110;
			end
		end
		else
			colour <= 3'b000;
	end
	
	// ------------------------------------------------------------------------assign crawling
	always @(posedge clock)
	begin: crawl_counter
	if (crawl_en) begin
		out_x <= x + q[4:0];
		out_y <= y + 4'd8 + q[7:5];
		end
		
	else if (init == 1'd1) begin
		out_x <= 8'd20 + q[3:0];
		out_y <= 7'd75 + q[7:4];
		end
		
	else begin 
		out_x <= x + q[3:0];
		out_y <= y + q[7:4];
		end
	end


//
//	
//	// -------assign crawling
//	always @(posedge clock)
//	begin: crawl_counter
//	if (crawl_en) begin
//		out_x <= 8'd20 + q[2:0];
//		out_y <= 7'd70 + 2'd2 + q[3];
//		end
//		
//	else if (init == 1'd1) begin
//		out_x <= 8'd20 + q[1:0];
//		out_y <= 7'd70 + q[3:2];
//		end
//		
//	else begin 
//		out_x <= x + q[1:0];
//		out_y <= y + q[3:2];
//		end
//	end
	
//	always @(posedge clock)
//	begin: init_x_y
//	if (init == 1'd0) begin
//			y <= 7'd70;
//			x <= 8'd20;
//			reach_top <= 1'b0;
//			finish_jump <= 1'b0;
//		end
//	else begin
//		y <= y;
//		x <= x;
//		reach_top <= reach_top;
//		finish_jump <= finish_jump;
//	end
//	end
//	
//	
	
	
endmodule








// control module
module control1(clock, resetn, press_crawl, press_jump, finish_erase, finish_jump, jump_change_en, 
					draw, plot, jumping, colour_black, erase_en, crawl_en, jump_en, init);
					
	input clock, resetn, press_crawl, press_jump, finish_erase, finish_jump, jump_change_en;
	
	//——————————————————————————————————————————————————————————————————————————————————[][][][][][]
	output reg draw, plot, jumping, colour_black, erase_en, crawl_en, jump_en, init;
	
//			jumping = 1'b0;
//		colour_black = 1'b0;
//		erase_en = 1'b0;
//		crawl_en = 1'b0;
//		jump_en = 1'b0;
//		draw = 1'b0;
//		plot = 1'b0;
//		init = 1'b0;

	
	reg [3:0] current_state, next_state;
	
	localparam 
					Draw = 4'd0,
					Erase_to_crawl = 4'd1,
					Erase_to_draw = 4'd2,
					Up = 4'd3,
					Down = 4'd4,
					Draw_jump = 4'd5,
					Erase_to_jump = 4'd6,
					Draw_wait = 4'd7;

					

	always @(*)
	begin: state_table
		case (current_state)
			
			// initial draw state ————————————————————————————————————————————>>
			Draw: begin
				if (press_crawl && ~press_jump)
					next_state = Erase_to_crawl;
				else if (press_jump && ~press_crawl)
					next_state = Erase_to_jump;
				else 
					next_state = Draw;
			end
			
			//Erase for crawling position ------------------------------------------->>
			Erase_to_crawl: next_state = finish_erase ? Down : Erase_to_crawl;
			
			
			//Erase for new jumping position ------------------------------------------------------------------------->>
			Erase_to_jump: next_state = finish_erase ? Up : Erase_to_jump;
			
			
			//State for crawling ----------------------------------------------------->>
			Down: next_state = (~press_crawl) ? Erase_to_draw : Down; 
			
			
//			Erase_to_jump: begin
//				if (finish_erase) // finish_erase is the erase delay
//					next_state = Up;
//				else 
//					next_state = Erase_to_jump;
//				end


			// Erase CRAWLING to draw state --------------------------------------->>
			Erase_to_draw: next_state = finish_erase ? Draw : Erase_to_draw;
			
			
			// State for Changing jumping position ————————————————————————————————————------------------------------———————>>
			Up: next_state = finish_jump ? Draw_wait : Draw_jump;
				
			//------------------------------------------------------------------------------------------------------pause for some time
			Draw_jump: next_state = (jump_change_en == 1'b1) ? Erase_to_jump : Draw_jump; 
			
			//------------------------------------------------------------------------------------------------------ hold while press key
			Draw_wait: next_state = (press_jump) ? Draw_wait : Draw;
			
			default: next_state = Draw;
		endcase
	end
	
	
	
	always @(*)
	begin: signals
		jumping = 1'b0;
		colour_black = 1'b0;
		erase_en = 1'b0;
		crawl_en = 1'b0;
		jump_en = 1'b0;
		draw = 1'b0;
		plot = 1'b0;
		init = 1'b0;
		case (current_state)
		Draw: begin
			draw = 1'b1;
			colour_black = 1'b1;
			plot = 1'b1;
			init = 1'b1;
			end
		Draw_wait: begin
			draw = 1'b1;
			colour_black = 1'b1;
			plot = 1'b1;
			init = 1'b1;
			end
		// Erase Crawling ------------->>
		Erase_to_draw: begin
			erase_en = 1'd1;
			draw = 1'b1;
			plot = 1'b1;
			crawl_en = 1'b1;
			end
		Erase_to_crawl : begin
			erase_en = 1'b1;
			draw = 1'b1;
			plot = 1'b1;
			end
		Down : begin
			crawl_en = 1'b1;
			plot = 1'b1;
			draw = 1'b1;
			colour_black = 1'b1;
			end
		Erase_to_jump : begin
			erase_en = 1'b1;
			draw = 1'b1;
			plot = 1'b1;
			end
		Up : begin
			jump_en = 1'b1;
			end
//		begin // new_x_y
//			if (reach_top == 1'b1) begin // reach the top
//				change_dir = 1'b1; // reach the top so change dir
//				jump_en = 1'b1;
//				end
//			else if (reach_ground == 1'b1)
//				jump_en = 1'b0;
//			else 
//				jump_en = 1'b1;
//			end 
		Draw_jump: begin // only set the y and check condition 
			jumping = 1'b1;
			draw = 1'b1;
			colour_black = 1'b1; // not black
			plot = 1'b1;
			end
		endcase
	end

	
	
	
	
	// change state
	always@(posedge clock)
		 begin: state_FFs
			  if(!resetn)
					current_state <= Draw;
			  else
					current_state <= next_state;
		 end // state_FFS
endmodule 

module ratedivider1(enable, load, clk, reset_n, q);
	input enable, clk, reset_n;
	input [27:0] load;
	output reg [27:0] q;
	
	always @(posedge clk, negedge reset_n)
	begin
		if (reset_n == 1'b0)
			q <= load;
		else if (enable == 1'b1)
			begin
				if (q == 0)
					q <= load;
				else
					q <= q - 1'b1;
			end
	end
endmodule 