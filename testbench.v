//*****************testbench for following code:*****************\\
 
//  Assembly Language Program           Machine Code (in Binary)

//    ADDI    R1, R0, 120         001010 00000 00001 0000000001111000
//    LW      R2, 0(R1)           001000 00001 00010 0000000000000000
//    ADDI    R2, R2, 45          001010 00010 00010 0000000000101101
//    SW      R2, 1(R1)           001001 00010 00001 0000000000000001
//    HLT                         111111 00000 00000 0000000000000000


module testbench_mips32;

    reg clk1, clk2;
    integer k;
    pipe_MIPS32 mips(clk1,clk2);

    initial begin
        clk1=0; clk2=0;
        repeat (50)
            begin
                #5 clk1=1; #5 clk1=0;
                #5 clk2=1; #5 clk2=0;
            end
    end

    initial begin

        for (k=0; k<31; k=k+1) begin
            mips.Reg[k]=k;          //initializing Regesters
        end
        //to avoid hazards (because of data dependency) dummy instructions are used
        mips.Mem[0]  = 32'h28010078;     //  ADDI    R1, R0, 120
        mips.Mem[1]  = 32'h0c631800;     //  OR      R3, R3, R3 --- Dummy Instruction
        mips.Mem[2]  = 32'h20220000;     //  LW      R2, 0(R1)        
        mips.Mem[3]  = 32'h0c631800;     //  OR      R3, R3, R3 --- Dummy Instruction
        mips.Mem[4]  = 32'h2842002d;     //  ADDI    R2, R2, 45
        mips.Mem[5]  = 32'h0c631800;     //  OR      R3, R3, R3 --- Dummy Instruction
        mips.Mem[6]  = 32'h24220001;     //  SW      R2, 1(R1)  
        mips.Mem[7]  = 32'hfc000000;     //  HLT

        mips.Mem[120]= 85;
        mips.PC      = 0;
        mips.HALTED  = 0;
        mips.TAKEN_BRANCH = 0;

        #500 $display("Mem[120]: %4d \nMem[121]: %4d", mips.Mem[120], mips.Mem[121]);
    end

    initial begin
        $dumpfile ("mips.vcd");
        $dumpvars (0, testbench_mips32);
        #600 $finish;
    end

endmodule