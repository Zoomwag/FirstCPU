/*
 * JB16 built-in program ROM
 *
 * Edit this case statement to change the program that becomes part of the chip.
 * Each instruction is 16 bits: opcode[15:12] and operand[11:0].
 */

`default_nettype none

module jb16_rom (
    input  wire [5:0]  address,
    output reg  [15:0] instruction
);

    always @(*) begin
        case (address)
            // Count down 3, 2, 1 on the 16-bit output.
            6'd0:  instruction = 16'h1003; // LDI  0x03
            6'd1:  instruction = 16'hE000; // OUT
            6'd2:  instruction = 16'h0004; // DEC
            6'd3:  instruction = 16'hC001; // JNZ  address 1

            // Prove that the datapath and RAM are genuinely 16-bit.
            6'd4:  instruction = 16'h1055; // LDI  0x55
            6'd5:  instruction = 16'h20AA; // LUI  0xAA -> accumulator = 0xAA55
            6'd6:  instruction = 16'h9000; // STORE RAM[0]
            6'd7:  instruction = 16'h1000; // LDI  0x00
            6'd8:  instruction = 16'h8000; // LOAD RAM[0]
            6'd9:  instruction = 16'hE000; // OUT -> 0xAA55

            // Forever read the 8 input pins, add one, and output 16 bits.
            6'd10: instruction = 16'hD000; // IN
            6'd11: instruction = 16'h3001; // ADDI 1
            6'd12: instruction = 16'hE000; // OUT
            6'd13: instruction = 16'hA00A; // JMP address 10

            // Unused ROM addresses safely halt.
            default: instruction = 16'hF000;
        endcase
    end

endmodule

`default_nettype wire
