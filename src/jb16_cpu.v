/*
 * JB16 - small educational 16-bit accumulator CPU
 *
 * Main parts:
 *   - 16-bit accumulator
 *   - 16-bit ALU
 *   - 64-word program address space
 *   - 8 words of 16-bit data RAM
 *   - zero, carry and negative flags
 *   - jumps, input, output and halt
 *
 * One instruction completes on each rising clock edge.
 */

`default_nettype none

module jb16_cpu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [7:0]  input_port,
    output wire [15:0] output_port
);

    // Main CPU registers.
    reg [15:0] accumulator;
    reg [15:0] output_register;
    reg [5:0]  program_counter;
    reg        zero_flag;
    reg        carry_flag;
    reg        negative_flag;
    reg        halted;

    // Eight 16-bit RAM words. Addressed with operand[2:0].
    reg [15:0] data_memory [0:7];
    integer i;

    // Current instruction fields.
    wire [15:0] instruction;
    wire [3:0]  opcode;
    wire [11:0] operand;

    assign opcode  = instruction[15:12];
    assign operand = instruction[11:0];

    jb16_rom rom (
        .address(program_counter),
        .instruction(instruction)
    );

    // Primary instruction opcodes.
    localparam [3:0] OP_SYSTEM = 4'h0;
    localparam [3:0] OP_LDI    = 4'h1;
    localparam [3:0] OP_LUI    = 4'h2;
    localparam [3:0] OP_ADDI   = 4'h3;
    localparam [3:0] OP_SUBI   = 4'h4;
    localparam [3:0] OP_ANDI   = 4'h5;
    localparam [3:0] OP_ORI    = 4'h6;
    localparam [3:0] OP_XORI   = 4'h7;
    localparam [3:0] OP_LOAD   = 4'h8;
    localparam [3:0] OP_STORE  = 4'h9;
    localparam [3:0] OP_JMP    = 4'hA;
    localparam [3:0] OP_JZ     = 4'hB;
    localparam [3:0] OP_JNZ    = 4'hC;
    localparam [3:0] OP_IN     = 4'hD;
    localparam [3:0] OP_OUT    = 4'hE;
    localparam [3:0] OP_HALT   = 4'hF;

    // Sub-operations used when opcode is 0.
    localparam [3:0] SYS_NOP = 4'h0;
    localparam [3:0] SYS_SHL = 4'h1;
    localparam [3:0] SYS_SHR = 4'h2;
    localparam [3:0] SYS_INC = 4'h3;
    localparam [3:0] SYS_DEC = 4'h4;
    localparam [3:0] SYS_NOT = 4'h5;
    localparam [3:0] SYS_CLC = 4'h6;

    // ALU operation numbers must match jb16_alu.v.
    localparam [3:0] ALU_PASS_B = 4'h0;
    localparam [3:0] ALU_ADD    = 4'h1;
    localparam [3:0] ALU_SUB    = 4'h2;
    localparam [3:0] ALU_AND    = 4'h3;
    localparam [3:0] ALU_OR     = 4'h4;
    localparam [3:0] ALU_XOR    = 4'h5;
    localparam [3:0] ALU_NOT    = 4'h6;
    localparam [3:0] ALU_SHL    = 4'h7;
    localparam [3:0] ALU_SHR    = 4'h8;
    localparam [3:0] ALU_INC    = 4'h9;
    localparam [3:0] ALU_DEC    = 4'hA;

    reg  [3:0]  alu_operation;
    reg  [15:0] alu_b;
    wire [15:0] alu_result;
    wire        alu_carry;
    wire        alu_zero;
    wire        alu_negative;

    jb16_alu alu (
        .a(accumulator),
        .b(alu_b),
        .operation(alu_operation),
        .result(alu_result),
        .carry(alu_carry),
        .zero(alu_zero),
        .negative(alu_negative)
    );

    // Choose the ALU operation and second input for the current instruction.
    always @(*) begin
        alu_operation = ALU_PASS_B;
        alu_b         = 16'h0000;

        case (opcode)
            OP_SYSTEM: begin
                case (operand[3:0])
                    SYS_SHL: alu_operation = ALU_SHL;
                    SYS_SHR: alu_operation = ALU_SHR;
                    SYS_INC: alu_operation = ALU_INC;
                    SYS_DEC: alu_operation = ALU_DEC;
                    SYS_NOT: alu_operation = ALU_NOT;
                    default: alu_operation = ALU_PASS_B;
                endcase
            end

            OP_LDI: begin
                alu_operation = ALU_PASS_B;
                alu_b         = {8'h00, operand[7:0]};
            end

            OP_LUI: begin
                alu_operation = ALU_PASS_B;
                alu_b         = {operand[7:0], accumulator[7:0]};
            end

            OP_ADDI: begin
                alu_operation = ALU_ADD;
                alu_b         = {8'h00, operand[7:0]};
            end

            OP_SUBI: begin
                alu_operation = ALU_SUB;
                alu_b         = {8'h00, operand[7:0]};
            end

            OP_ANDI: begin
                alu_operation = ALU_AND;
                alu_b         = {4'h0, operand};
            end

            OP_ORI: begin
                alu_operation = ALU_OR;
                alu_b         = {4'h0, operand};
            end

            OP_XORI: begin
                alu_operation = ALU_XOR;
                alu_b         = {4'h0, operand};
            end

            default: begin
                alu_operation = ALU_PASS_B;
                alu_b         = 16'h0000;
            end
        endcase
    end

    assign output_port = output_register;

    // CPU state updates.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulator     <= 16'h0000;
            output_register <= 16'h0000;
            program_counter <= 6'd0;
            zero_flag       <= 1'b1;
            carry_flag      <= 1'b0;
            negative_flag   <= 1'b0;
            halted          <= 1'b0;

            for (i = 0; i < 8; i = i + 1) begin
                data_memory[i] <= 16'h0000;
            end
        end else if (enable && !halted) begin
            // Most instructions continue to the next ROM address.
            // A taken jump overwrites this assignment below.
            program_counter <= program_counter + 6'd1;

            case (opcode)
                OP_SYSTEM: begin
                    case (operand[3:0])
                        SYS_NOP: begin
                            // Deliberately do nothing.
                        end

                        SYS_SHL,
                        SYS_SHR,
                        SYS_INC,
                        SYS_DEC,
                        SYS_NOT: begin
                            accumulator   <= alu_result;
                            zero_flag     <= alu_zero;
                            carry_flag    <= alu_carry;
                            negative_flag <= alu_negative;
                        end

                        SYS_CLC: begin
                            carry_flag <= 1'b0;
                        end

                        default: begin
                            // Unknown system operations act as NOP.
                        end
                    endcase
                end

                OP_LDI,
                OP_LUI,
                OP_ADDI,
                OP_SUBI,
                OP_ANDI,
                OP_ORI,
                OP_XORI: begin
                    accumulator   <= alu_result;
                    zero_flag     <= alu_zero;
                    carry_flag    <= alu_carry;
                    negative_flag <= alu_negative;
                end

                OP_LOAD: begin
                    accumulator   <= data_memory[operand[2:0]];
                    zero_flag     <= (data_memory[operand[2:0]] == 16'h0000);
                    carry_flag    <= 1'b0;
                    negative_flag <= data_memory[operand[2:0]][15];
                end

                OP_STORE: begin
                    data_memory[operand[2:0]] <= accumulator;
                end

                OP_JMP: begin
                    program_counter <= operand[5:0];
                end

                OP_JZ: begin
                    if (zero_flag) begin
                        program_counter <= operand[5:0];
                    end
                end

                OP_JNZ: begin
                    if (!zero_flag) begin
                        program_counter <= operand[5:0];
                    end
                end

                OP_IN: begin
                    accumulator   <= {8'h00, input_port};
                    zero_flag     <= (input_port == 8'h00);
                    carry_flag    <= 1'b0;
                    negative_flag <= 1'b0;
                end

                OP_OUT: begin
                    output_register <= accumulator;
                end

                OP_HALT: begin
                    halted          <= 1'b1;
                    program_counter <= program_counter;
                end

                default: begin
                    // All 4-bit opcode values are already covered.
                end
            endcase
        end
    end

endmodule

`default_nettype wire
