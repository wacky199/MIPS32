module all_opcodes;
	parameter ADD=6'b000000,
		  SUB=6'b000001,
		  AND=6'b000010,
		  OR =6'b000011,
		  MUL=6'b000101,
		  STL=6'b000100,
		  HTL=6'b111111,

		  LW =6'b001000,
		  SW =6'b001001,
		  ADDI=6'b001010,
		  SUBI=6'b001011,
		  STLI=6'b001100,
		  BNEQZ=6'b001101,
		  BENQ=6'b001110,

		  RR_ALU=3'b000,
		  RM_ALU=3'b001,
		  LOAD=3'b010,
		  STORE=3'b011,
		  BRANCH=3'b100,
		  HALT=3'b101;
endmodule
