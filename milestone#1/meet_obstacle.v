module meet_obstacle (
	Clk,reset,
	Q_Initial,
	Q_Check,
	Q_Lose, 
	Start, Ack, 
	X_Edge_Left,
	X_Edge_Right,
	Y_Edge_Top,
	Y_Edge_Bottom,
	Character_X_L, Character_X_R, Character_Y_T, Character_Y_B
	);

// INPUTS //
input 	Clk, reset, Start, Ack;
input [9:0] Character_X_L; // character's x left
input [9:0] Character_Y_T; // character's y top
input [9:0] Character_X_R; // character's x right
input [9:0] Character_Y_B; // character's y bottom
input	[9:0] X_Edge_Left; // 10-bit x edge of current obstacle (left edge)
input	[9:0] X_Edge_Right; // 10-bit x edge of current obstacle (right edge)
input	[9:0] Y_Edge_Top; // 10 bit y edge of current obstacle (top edge)

// OUTPUTS //
output 	Q_Initial, Q_Check, Q_Lose;

reg [2:0] state;

reg [9:0] t1;
reg [9:0] t2;
reg [9:0] t3;
reg [9:0] t4;

integer loseCounter;

//reg timer_out;
//reg [3:0] count;

assign {Q_Lose, Q_Check, Q_Initial } = state;

localparam
			QInitial = 3'b001,
			QCheck	= 3'b010,
			QLose 	= 3'b100,
			UNK		= 3'bXXX;
			
always @ (posedge Clk, posedge reset)
begin
	if(reset)
	begin
		state <= QInitial;
	end
	else
	
	begin
		case(state)

			QInitial:
			begin
				if(Start)
					state <= QCheck;
			end	
			
			QCheck:
			begin
			// if characte collides with the obstacle (touches the top or the edges)
				if ((Character_Y_B <= Y_Edge_Top) && 
					(Character_X_R > X_Edge_Left || Character_X_L < X_Edge_Right))
					begin
						state <= QLose;
					end
			end	
			
			QLose:
			begin // do something when lose
				loseCounter <= loseCounter + 1;
			end

			default:
				state <= QInitial;
		endcase
	end
end
endmodule