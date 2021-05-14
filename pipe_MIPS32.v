'include "all_parameters.v"

module pipe_MIPS32(
	input clk1, clk2    		//two phase clock
);
	reg [31:0] PC, IF_ID_IR, IF_ID_NPC;		//NPC-> Next Instruction
       	reg [31:0] ID_EX_IR,  ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
	reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;
	reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
	reg [31:0] EX_MEM_cond;
	reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
	reg [31:0] Reg [0:31];		//Register Bank
	reg [31:0] Mem [0:1023];	//1024 x 32 memory

	reg HALTED; 			//Set after HLT instruction is completed (in WB stage) 
	reg TAKEN_BRANCH;		//Required to disable instructions after branch


		//********** //IF Stage\\ ***********\\

	always @(posedge clk1)
		if (HALTED==0)
		begin
			if(((EX_MEM_IR[31:26]==BEQZ) && (EX_MEM_cond==1)) || ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond ==0)))	//cond = (A==0)
			begin
				IF_ID_IR	 <= #2 Mem[EX_MEM_ALUOut];
				TAKEN_BRANCH	 <= #2 1'b1;
				IF_ID_NPC	 <= #2 EX_MEM_ALUOut +1;
				PC		 <= #2 EX_MEM_ALUOut +1;
			end
			else begin
				IF_ID_IR	 <= #2 Mem[PC];
				IF_ID_NPC	 <= #2 PC +1;
				PC		 <= #2 PC +1;
		       	end	       
		end

		//************** ID Stage************\\

	always @ (posedge clk2)
		if (HALTED==0)
	       	begin
			if (IF_ID_IR[25:21] == 5'b00000) 	ID_EX_A <= 0;
			else ID_EX_A	<= #2 Reg[IF_ID_IR[25:21]];	//"rs"

			if (IF_ID_IR[20:16] == 5'b00000)	ID_EX_B <= 0;
			else ID_EX_B	<= #2 Reg[IF_ID_IR[20:16]];	//"rt"

			ID_EX_NPC	<= #2 IF_ID_NPC;
			ID_EX_IR	<= #2 IF_ID_IR;
			ID_EX_Imm	<= #2 {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};	//16 bit Immediate data 


	case (IF_ID_IR[31:26])
		ADD, SUB, AND, OR, SLT, MUL: ID_EX_type <= #2 RR_ALU;
		AADI, SUBI, STLI	   : ID_EX_type <= #2 RM_ALU;
		LW			   : ID_EX_type <= #2 LOAD;
		SW			   : ID_EX_type <= #2 STORE;
		BNEQZ, BEQZ		   : ID_EX_type <= #2 BRANCH;
		HLT			   : ID_EX_type <= #2 HALT;
		default			   : ID_EX_type <= #2 HALT;
	endcase
	end


		//***************EX Stage****************\\

	always @ (posedge clk1)
		if (HALTED==0)
		begin
			EX_MEM_type	<= #2 ID_EX_type;
			EX_MEM_IR	<= #2 ID_EX_IR;
			TAKEN_BRANCH	<= #2 0;

			case (ID_EX_type)
				RR_ALU:	begin
					case (ID_EX_IR[31:26])	//opcode
						ADD: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;
                                                SUB: EX_MEM_ALUOut <= #2 ID_EX_A
 - ID_EX_B;
                                                AND: EX_MEM_ALUOut <= #2 ID_EX_A
 & ID_EX_B;
                                                OR: EX_MEM_ALUOut <= #2 ID_EX_A
 | ID_EX_B;
                                                SLT: EX_MEM_ALUOut <= #2 ID_EX_A
 < ID_EX_B;
                                                MUL: EX_MEM_ALUOut <= #2 ID_EX_A
 * ID_EX_B;
                                                default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
					endcase
					end

				RM_ALU: begin
					case (ID_EX_IR[31:26])	//opcode
                                               ADDI: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
                                               SUBI: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
                                               STLI: EX_MEM_ALUOut <= #2 ID_EX_A <  ID_EX_Imm;
					       default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
				        endcase
			       		end 


				LOAD, STORE: begin:
						EX_MEM_ALUOut	<= #2 ID_EX_A + ID_EX_Imm;
						EX_MEM_B	<= #2 ID_EX_B;
					end

				BRANCH:	begin
					EX_MEM_ALUOut	<= #2 ID_EX_NPC + ID_EX_Imm;
					EX_MEM_cond	<= #2 (ID_EX_A == 0);
				end
			endcase
		end


		//***************MEM Stage***************\\

	always @ (posedge clk2)
		if (HALTED==0)
		begin
			MEM_WB_type	<= #2 EX_MEM_type;
			MEM_WB_IR	<= #2 EX_MEM_IR;
			
			case (EX_MEM_type)
				RR_ALU, RM_ALU:
					MEM_WB_LMD	<= #2 Mem[EX_MEM_ALUOut];
				LOAD:	MEM_WB_LMD	<= #2 Mem[EX_MEM_ALUOut];
				STORE:	if (TAKEN_BRANCH==0)	//disable write
					Mem[EX_MEM_ALUOut]	<= #2 EX_MEM_B;
			endcase
		end

