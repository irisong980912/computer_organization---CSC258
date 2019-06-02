module sfx (reset, clock_27mhz, audio_reset_b, ac97_sdata_out, ac97_sdata_in, ac97_synch, ac97_bit_clock, mode, play);

   parameter VOL_PARAM = 5'd30;

   input reset, clock_27mhz;
   output audio_reset_b;
   output ac97_sdata_out;
   input ac97_sdata_in;
   output ac97_synch;
   input ac97_bit_clock;
   
   //sfx interface
   input [1:0] mode; //selects 1 of 4 effects
   input play; //start playing selected effect
   
   wire ready;
   wire [7:0] command_address;
   wire [15:0] command_data;
   wire command_valid;
   
   wire [19:0] left_out_data;
   wire [19:0] right_out_data;
   wire [19:0] left_in_data, right_in_data;
   wire [4:0] volume;
   wire source;
   
   //hard code volume/source
   assign volume = VOL_PARAM; //a reasonable volume
   assign source = 1'b1; //microphone

   //
   // Reset controller
   //
   reg audio_reset_b;
   reg [9:0] reset_count;

   ////////////////////////////////////////////////////////////////////////////
   //
   // Reset Generation
   //
   // A shift register primitive is used to generate an active-high reset
   // signal that remains high for 16 clock cycles after configuration finishes
   // and the FPGA's internal clocks begin toggling.
   //
   ////////////////////////////////////////////////////////////////////////////

   wire one_time_reset;
   SRL16 reset_sr (.D(1'b0), .CLK(clock_27mhz), .Q(one_time_reset), .A0(1'b1), .A1(1'b1), .A2(1'b1), .A3(1'b1));
   defparam reset_sr.INIT = 16'hFFFF;

   always @(posedge clock_27mhz) begin
     if (one_time_reset)
	begin
	   audio_reset_b <= 1'b0;
	   reset_count <= 0;
	end
     else if (reset_count == 1023)
	audio_reset_b <= 1'b1;
     else
	reset_count <= reset_count+1;
   end
   
   ac97 ac97(ready, command_address, command_data, command_valid,
	     left_out_data, 1'b1, right_out_data, 1'b1, left_in_data, 
	     right_in_data, ac97_sdata_out, ac97_sdata_in, ac97_synch,
	     ac97_bit_clock);
   
   ac97commands cmds(clock_27mhz, ready, command_address, command_data,
		     command_valid, volume, source); 

   
   sound_fsm sound_fsm(reset, clock_27mhz, play, mode, ready, left_out_data, right_out_data);
  
  endmodule

  module sound_fsm(reset, clock_27mhz, play, mode, ready, left_out_data, right_out_data);

   input reset, clock_27mhz;
   input ready;
   input play;
   input [1:0] mode;

   output [19:0] left_out_data;
   output [19:0] right_out_data;

   parameter S_IDLE = 2'd0;
   parameter S_START = 2'd1;
   parameter S_PLAY = 2'd2;
   
   reg [19:0] left_out_data;

   reg [1:0] state = S_IDLE;
   reg [1:0] mode_l; //latched in the mode
      
   //control signals for effects modules
   wire [3:0] done;
   wire [3:0] start;
   wire [19:0] pcm_out_0, pcm_out_1, pcm_out_2, pcm_out_3;
   
   reg done_cur;
   
   reg old_ready;   
   always @ (posedge clock_27mhz)
   	old_ready <= reset ? 0 : ready;

   assign next_sample = (ready && ~old_ready);


   //instantiate the FX modules
   slash_fx    fx0(reset, clock_27mhz, next_sample, pcm_out_0, start[0], done[0]);
   ramp_fx     fx1(reset, clock_27mhz, next_sample, pcm_out_1, start[1], done[1]);
   triangle_fx fx2(reset, clock_27mhz, next_sample, pcm_out_2, start[2], done[2]);
   boing_fx    fx3(reset, clock_27mhz, next_sample, pcm_out_3, start[3], done[3]);
   
   
   always @ (posedge clock_27mhz)
   if(reset)
   	state <= S_IDLE;
   else
     case (state)
      S_IDLE:
         if(play)
         begin
            state <= S_START;
            mode_l <= mode;
         end
      S_START : state <= S_PLAY;
      S_PLAY: state <= done_cur ? S_IDLE : state;
      default: state <= S_IDLE;
     endcase

   assign start[0] = (state == S_START) && (mode_l == 2'd0);
   assign start[1] = (state == S_START) && (mode_l == 2'd1);
   assign start[2] = (state == S_START) && (mode_l == 2'd2);
   assign start[3] = (state == S_START) && (mode_l == 2'd3);
   
   always @(mode_l or done)
   case (mode_l)
      2'd0: done_cur = done[0];
      2'd1: done_cur = done[1];
      2'd2: done_cur = done[2];
      2'd3: done_cur = done[3];
   endcase

   always @(mode_l or state or pcm_out_0 or pcm_out_1 or pcm_out_2 or pcm_out_3)
     if(state == S_PLAY)
     case (mode_l)
      2'd0: left_out_data = pcm_out_0;
      2'd1: left_out_data = pcm_out_1;
      2'd2: left_out_data = pcm_out_2;
      2'd3: left_out_data = pcm_out_3;
     endcase
     
	else
	   //left_out_data = square_data;
        left_out_data = 20'h00000;
    //end always
    
   assign right_out_data = left_out_data; //mono output
   
endmodule
		 

module ac97 (ready,
	     command_address, command_data, command_valid,
	     left_data, left_valid,
	     right_data, right_valid,
	     left_in_data, right_in_data,
	     ac97_sdata_out, ac97_sdata_in, ac97_synch, ac97_bit_clock);

   output ready;
   input [7:0] command_address;
   input [15:0] command_data;
   input command_valid;
   input [19:0] left_data, right_data;
   input left_valid, right_valid;
   output [19:0] left_in_data, right_in_data;
   
   input ac97_sdata_in;
   input ac97_bit_clock;
   output ac97_sdata_out;
   output ac97_synch;
   
   reg ready;

   reg ac97_sdata_out;
   reg ac97_synch;

   reg [7:0] bit_count;

   reg [19:0] l_cmd_addr;
   reg [19:0] l_cmd_data;
   reg [19:0] l_left_data, l_right_data;
   reg l_cmd_v, l_left_v, l_right_v;
   reg [19:0] left_in_data, right_in_data;
   
   initial begin
      ready <= 1'b0;
      // synthesis attribute init of ready is "0";
      ac97_sdata_out <= 1'b0;
      // synthesis attribute init of ac97_sdata_out is "0";
      ac97_synch <= 1'b0;
      // synthesis attribute init of ac97_synch is "0";
      
      bit_count <= 8'h00;
      // synthesis attribute init of bit_count is "0000";
      l_cmd_v <= 1'b0;
      // synthesis attribute init of l_cmd_v is "0";
      l_left_v <= 1'b0;
      // synthesis attribute init of l_left_v is "0";
      l_right_v <= 1'b0;
      // synthesis attribute init of l_right_v is "0";

      left_in_data <= 20'h00000;
      // synthesis attribute init of left_in_data is "00000";
      right_in_data <= 20'h00000;
      // synthesis attribute init of right_in_data is "00000";
   end
   
   always @(posedge ac97_bit_clock) begin
      // Generate the sync signal
      if (bit_count == 255)
	ac97_synch <= 1'b1;
      if (bit_count == 15)
	ac97_synch <= 1'b0;

      // Generate the ready signal
      if (bit_count == 128)
	ready <= 1'b1;
      if (bit_count == 2)
	ready <= 1'b0;
      
      // Latch user data at the end of each frame. This ensures that the
      // first frame after reset will be empty.
      if (bit_count == 255)
	begin
	   l_cmd_addr <= {command_address, 12'h000};
	   l_cmd_data <= {command_data, 4'h0};
	   l_cmd_v <= command_valid;
	   l_left_data <= left_data;
	   l_left_v <= left_valid;
	   l_right_data <= right_data;
	   l_right_v <= right_valid;
	end
      
      if ((bit_count >= 0) && (bit_count <= 15))
	// Slot 0: Tags
	case (bit_count[3:0])
	  4'h0: ac97_sdata_out <= 1'b1;      // Frame valid
	  4'h1: ac97_sdata_out <= l_cmd_v;   // Command address valid
	  4'h2: ac97_sdata_out <= l_cmd_v;   // Command data valid
	  4'h3: ac97_sdata_out <= l_left_v;  // Left data valid
	  4'h4: ac97_sdata_out <= l_right_v; // Right data valid
	  default: ac97_sdata_out <= 1'b0;
	endcase
	  
      else if ((bit_count >= 16) && (bit_count <= 35))
	// Slot 1: Command address (8-bits, left justified)
	ac97_sdata_out <= l_cmd_v ? l_cmd_addr[35-bit_count] : 1'b0;
      
      else if ((bit_count >= 36) && (bit_count <= 55))
	// Slot 2: Command data (16-bits, left justified)
	ac97_sdata_out <= l_cmd_v ? l_cmd_data[55-bit_count] : 1'b0;
      
      else if ((bit_count >= 56) && (bit_count <= 75))
	begin
	   // Slot 3: Left channel
	   ac97_sdata_out <= l_left_v ? l_left_data[19] : 1'b0;
	   l_left_data <= { l_left_data[18:0], l_left_data[19] };
	end
      else if ((bit_count >= 76) && (bit_count <= 95))
	// Slot 4: Right channel
	   ac97_sdata_out <= l_right_v ? l_right_data[95-bit_count] : 1'b0;
      else 
	ac97_sdata_out <= 1'b0;
      
      bit_count <= bit_count+1;
      
   end // always @ (posedge ac97_bit_clock)

   always @(negedge ac97_bit_clock) begin
      if ((bit_count >= 57) && (bit_count <= 76))
	// Slot 3: Left channel
	left_in_data <= { left_in_data[18:0], ac97_sdata_in };
      else if ((bit_count >= 77) && (bit_count <= 96))
	// Slot 4: Right channel
	right_in_data <= { right_in_data[18:0], ac97_sdata_in };
   end
   
endmodule

///////////////////////////////////////////////////////////////////////////////

module ac97commands (clock, ready, command_address, command_data, 
		     command_valid, volume, source);
   
   input clock;
   input ready;
   output [7:0] command_address;
   output [15:0] command_data;
   output command_valid;
   input [4:0] volume;
   input source;
      
   reg [23:0] command;
   reg command_valid;

   reg old_ready;
   reg done;
   reg [3:0] state;

   initial begin
      command <= 4'h0;
      // synthesis attribute init of command is "0";
      command_valid <= 1'b0;
      // synthesis attribute init of command_valid is "0";
      done <= 1'b0;
      // synthesis attribute init of done is "0";
      old_ready <= 1'b0;
      // synthesis attribute init of old_ready is "0";
      state <= 16'h0000;
      // synthesis attribute init of state is "0000";
   end
      
   assign command_address = command[23:16];
   assign command_data = command[15:0];

   wire [4:0] vol;
   assign vol = 31-volume;
   	      
   always @(posedge clock) begin
      if (ready && (!old_ready))
	state <= state+1;
      
      case (state)
	4'h0: // Read ID
	  begin
	     command <= 24'h80_0000;
	     command_valid <= 1'b1;
	  end
      	4'h1: // Read ID
	  command <= 24'h80_0000;
	4'h2: // Master volume
	  command <= { 8'h02, 3'b000, vol, 3'b000, vol };
	4'h3: // Aux volume
	  command <= { 8'h04, 3'b000, vol, 3'b000, vol };
	4'h4: // Mono volume
	  command <= 24'h06_8000;
	4'h5: // PCM volume
	  command <= 24'h18_0808;
	4'h6: // Record source select
	  if (source)
	    command <= 24'h1A_0000; // microphone
	  else
	    command <= 24'h1A_0404; // line-in
	4'h7: // Record gain
	  command <= 24'h1C_0000;
	4'h8: // Line in gain
	  command <= 24'h10_8000;
	//4'h9: // Set jack sense pins
	  //command <= 24'h72_3F00;
	4'hA: // Set beep volume
	  command <= 24'h0A_0000;
	//4'hF: // Misc control bits
	  //command <= 24'h76_8000;
	default:
	  command <= 24'h80_0000;
      endcase // case(state)

      old_ready <= ready;
      
   end // always @ (posedge clock)

endmodule // ac97commands

module slash_fx (reset, clock, next_sample, pcm_data, start, done);

   input reset;
   input clock;
   input next_sample;
   input start;

   output [19:0] pcm_data;
   output done;

   reg old_ready;
   reg [19:0] pcm_data;
   reg [25:0] count;

   parameter seconds = 1;
//   parameter LAST_COUNT = 48000 * seconds;
   parameter LAST_COUNT = 8000 * seconds;


   always @ (posedge clock)
   begin
      if(reset)
	    count <= LAST_COUNT;
      if(start)
	    count <= 0;

      else if (next_sample)
	     count <= (done) ? count : count + 1;
   end
   
   assign done = (count >= LAST_COUNT);


   /////////////////////////////////////////////////////////// 
   //  Now actually output tone...
   ///////////////////////////////////////////////////////////
 
  reg [19:0] INC = 2000;

  reg up;

  always @ (posedge clock)
  begin
    if(start)
    begin
       pcm_data <= 20'h05555;
	  INC  <= 20'd2000;
       up <= 1;
    end


    if(next_sample)
    begin
      if(up)
          pcm_data <= pcm_data + INC;
	  else
	     pcm_data <= pcm_data - INC;

       INC <= INC + 100;
    end

    if (up && pcm_data >=  20'hF0F00)
         up <= ~up;

    if (~up && pcm_data <= 20'h05555)
         up <= ~up;
    
  end

endmodule

module boing_fx (reset, clock, next_sample, pcm_data, start, done);
   
   input reset;
   input clock;
   input next_sample;
   input start;

   output [19:0] pcm_data;
   output done;

   reg old_ready;
   reg [19:0] pcm_data;
   reg [25:0] count;

   parameter seconds = 2;
//   parameter LAST_COUNT = 48000 * seconds;
   parameter LAST_COUNT = 8000 * seconds;


   always @ (posedge clock)
   begin
      if(reset)
	    count <= LAST_COUNT;
      if(start)
	    count <= 0;

      else if (next_sample)
	     count <= (done) ? count : count + 1;
   end
   
   assign done = (count >= LAST_COUNT);

   /////////////////////////////////////////////////////////// 
   //  Now actually output tone...
   ///////////////////////////////////////////////////////////
 
  reg [19:0] INC;

  reg up;
  reg inc_up;

  always @ (posedge clock)
  begin
    if(start)
    begin
       pcm_data <= 20'h05555;
	  INC  <= 20'd110;
       up <= 1;
	  inc_up <= 1;
    end


    if(next_sample)
    begin
      if(up)
          pcm_data <= pcm_data + INC;
	  else
	     pcm_data <= pcm_data - INC;

       if(inc_up)
          INC <= INC + 10;
       else
	     INC <= INC - 10;
    end

    if (up && pcm_data >=  20'hF0F00)
         up <= ~up;
    if (~up && pcm_data <= 20'h05555)
         up <= ~up;
    
  end

endmodule

module triangle_fx (reset, clock, next_sample, pcm_data, start, done);

   input reset;
   input clock;
   input next_sample;
   input start;

   output [19:0] pcm_data;
   output done;

   reg old_ready;
   reg [19:0] pcm_data;
   reg [25:0] count;

   parameter seconds = 2;
//   parameter LAST_COUNT = 48000 * seconds;
   parameter LAST_COUNT = 8000 * seconds;


   always @ (posedge clock)
   begin
      if(reset)
	    count <= LAST_COUNT;
      if(start)
	    count <= 0;

      else if (next_sample)
	     count <= (done) ? count : count + 1;
   end
   
   assign done = (count >= LAST_COUNT);

   /////////////////////////////////////////////////////////// 
   //  Now actually output tone...
   ///////////////////////////////////////////////////////////
 
  parameter INC = 2000;

  reg up;

  always @ (posedge clock)
  begin
    if(start)
    begin
       pcm_data <= 20'h05555;
       up <= 1;
    end


    if(next_sample)
    begin
      if(up)
          pcm_data <= pcm_data + INC;
	  else
	     pcm_data <= pcm_data - INC;
    end

    if (up && pcm_data >=  20'hF0F00)
         up <= ~up;

    if (~up && pcm_data <= 20'h05555)
         up <= ~up;
    
  end

endmodule

module ramp_fx (reset, clock, next_sample, pcm_data, start, done);

   input reset;
   input clock;
   input next_sample;
   input start;

   output [19:0] pcm_data;
   output done;

   reg old_ready;
   reg [19:0] pcm_data;
   reg [25:0] count;

   parameter seconds = 2;
//   parameter LAST_COUNT = 48000 * seconds;
   parameter LAST_COUNT = 8000 * seconds;


   always @ (posedge clock)
   begin
      if(reset)
	    count <= LAST_COUNT;
      if(start)
	    count <= 0;

      else if (next_sample)
	     count <= (done) ? count : count + 1;
   end
   
   assign done = (count >= LAST_COUNT);

   /////////////////////////////////////////////////////////// 
   //  Now actually output tone...
   ///////////////////////////////////////////////////////////

  always @ (posedge clock)
  begin
    if(start)
       pcm_data <= 0;
    if(next_sample)
       pcm_data <= pcm_data + 800;
  end

endmodule