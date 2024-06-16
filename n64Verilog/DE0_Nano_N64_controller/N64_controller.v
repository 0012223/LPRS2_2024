// --------------------------------------------------------------------
// Copyright (c) 2017 by FPGALOVER 
// --------------------------------------------------------------------
//                     web: http://www.fpgalover.com
//                     email: admin@fpgalover.com or hbecerra@ece.ubc.ca
// --------------------------------------------------------------------
//	Author: Holguer Andres Becerra Daza
// Module: N64 Controller Interface
// --------------------------------------------------------------------
// Bits Description:
// 				A 			--> buttons[1]
// 				B 			--> buttons[2]
// 				Z 			--> buttons[3]
// 				Start 	--> buttons[4]
// 				Up 		--> buttons[5]        
// 				Down 		--> buttons[6]   
// 				Left 		--> buttons[7]
// 				Right		--> buttons[8]
// 				N/A 		--> buttons[9]
// 				N/A 		--> buttons[10]
// 				L 			--> buttons[11]
// 				R 			--> buttons[12]
// 				C-UP 		--> buttons[13]  
// 				C-DOWN	--> buttons[14]     
// 				C-Left	--> buttons[15]
// 				C-Right	--> buttons[16]
// 				X-Axis 	--> buttons[24:17]
// 				Y-Axis 	--> buttons[32:25]





module N64_controller(
		input clk_50MHZ,
		inout data,
		input start,
		output reg [33:0]buttons=34'd0,
		output reg alive=1'd0
);
						//counter_en___finish_______oe__get__state
localparam IDLE_FSM		 =	8'b0___________0________0___0_0000;
localparam POLL_FSM		 =	8'b0___________0________1___0_0000;
localparam SEND0_FSM1	 =	8'b0___________0________1___0_0010;
localparam SEND0_FSM2	 =	8'b0___________0________1___0_0011;
localparam SEND1_FSM1	 =	8'b0___________0________1___0_0100;
localparam SEND1_FSM2	 =	8'b0___________0________1___0_0101;
localparam GET_FSM 		 =	8'b1___________0________0___0_0110;
localparam FINISH_FSM 	 =	8'b0___________1________0___0_1110;

localparam THREEuSECONDS = 32'd150;
localparam ONEuSECONDS = 32'd50;
localparam HUNDRED_MS = 32'd400000;
  

reg [7:0]state=IDLE_FSM;
reg [31:0]counter_delay =32'd0;
reg [31:0]counter_delay_pulses =32'd0;
reg [3:0]counter_polling =4'd0;
reg [5:0]counting_data =6'd0;
wire [8:0]polling_data=9'b110000000;
reg [33:0]buffer_buttons=34'd0;
reg [7:0]counter=8'd0;
wire counter_en=state[7];
wire oe=state[5];
wire finish=state[6];
wire counting_data_clk=state[4];
wire data_out=state[0];
reg data_in=1'b0;
reg real_in=1'b0;
reg start_counter=1'b0;
assign data = oe ? data_out: 1'bz;
 
always@(posedge clk_50MHZ)
begin
	data_in<=data; 
end

wire sync_data;
wire sync_data_not;


async_trap_and_reset async_trap_and_reset_inst
(
	.async_sig(data_in) ,	// input  async_sig_sig
	.outclk(clk_50MHZ) ,	// input  outclk_sig
	.out_sync_sig(sync_data) ,	// output  out_sync_sig_sig
	.auto_reset(1'b1) ,	// input  auto_reset_sig
	.reset(1'b1) 	// input  reset_sig
);


async_trap_and_reset async_trap_and_reset_inst2
(
	.async_sig(~data_in) ,	// input  async_sig_sig
	.outclk(clk_50MHZ) ,	// input  outclk_sig
	.out_sync_sig(sync_data_not) ,	// output  out_sync_sig_sig
	.auto_reset(1'b1) ,	// input  auto_reset_sig
	.reset(1'b1) 	// input  reset_sig
);





always@(posedge clk_50MHZ)
begin
	if(sync_data)
	begin
		counter<=counter+1'b1;
	end
	else
	begin
		counter<=counter;
		if(!counter_en)
		begin
			counter<=0;
		end
	end
end

 

always@(posedge clk_50MHZ)
begin
	counter_delay_pulses<=counter_delay_pulses;
	if(sync_data_not)
	begin
		buttons[counter]<=(counter_delay_pulses[31:0]>=32'd100);
	end
	else if(sync_data)
	begin
		counter_delay_pulses<=0;
	end
	else
	begin
		if(counter_en)
		begin
			counter_delay_pulses<=counter_delay_pulses+1'b1;
		end
	end
end



always@(negedge finish)//debug counter keep alive N64
begin
	alive<=~alive;
end


always@(posedge data_out, posedge finish)
begin
	if(finish)
	begin
		counter_polling[3:0]<=4'd0;
	end
	else
	begin
		counter_polling[3:0]<=counter_polling[3:0]+1'b1;
	end
end




always@(posedge clk_50MHZ)
begin
	case(state[7:0])
	IDLE_FSM	:begin	 	
					counter_delay[31:0]<=0;
					state[7:0]<=IDLE_FSM;
					if(start)
					begin
						state[7:0]<=POLL_FSM;
					end
				 end
	POLL_FSM	:begin	 
					counter_delay[31:0]<=0;// otherwise go to get the data
					state[7:0]<=GET_FSM;
					if(counter_polling[3:0]<=4'd8)
					begin
						counter_delay[31:0]<=ONEuSECONDS;//send a 1 starting from 1 us
						state[7:0]<=SEND1_FSM1;
						if(polling_data[counter_polling[3:0]]==1'b0)
						begin
							counter_delay[31:0]<=THREEuSECONDS;
							state[7:0]<=SEND0_FSM1;//send a 0  starting from 3 us
						end
					end
				 end
	SEND0_FSM1	:begin// send a 0  
					state[7:0]<=SEND0_FSM1;
					counter_delay[31:0]<=counter_delay[31:0]-1'b1;
					if(counter_delay[31:0]==32'd0)
					begin
						state[7:0]<=SEND0_FSM2;
						counter_delay[31:0]<=ONEuSECONDS;
					end
				 end
	SEND0_FSM2	:begin
					state[7:0]<=SEND0_FSM2;
					counter_delay[31:0]<=counter_delay[31:0]-1'b1;
					if(counter_delay[31:0]==32'd0)
					begin
						state[7:0]<=POLL_FSM;
					end
				 end
	SEND1_FSM1	:begin
					state[7:0]<=SEND1_FSM1;
					counter_delay[31:0]<=counter_delay[31:0]-1'b1;
					if(counter_delay[31:0]==32'd0)
					begin
						state[7:0]<=SEND1_FSM2;
						counter_delay[31:0]<=THREEuSECONDS;
					end
				 end
	SEND1_FSM2	:begin
					state[7:0]<=SEND1_FSM2;
					counter_delay[31:0]<=counter_delay[31:0]-1'b1;
					if(counter_delay[31:0]==32'd0)
					begin
						state[7:0]<=POLL_FSM;
					end
				 end
	GET_FSM 	:begin	 
					state[7:0]<=GET_FSM;
					counter_delay[31:0]<=HUNDRED_MS;// DELAY AFTER POLLING AND GETTING DATA
				   if(counter[7:0]>=8'd33)// wait untilt there are 33 pulses coming from the N64 controller
					begin
						state[7:0]<=FINISH_FSM;
					end
				 end
	FINISH_FSM 	:begin
					state[7:0]<=FINISH_FSM;
					counter_delay[31:0]<=counter_delay[31:0]-1'b1;
					if(counter_delay[31:0]==32'd0)
					begin
						state[7:0]<=IDLE_FSM;
					end
				 end
	default		:begin
					state[7:0]<=IDLE_FSM;
					counter_delay[31:0]<=32'd0;
				 end
	endcase 
end


endmodule
