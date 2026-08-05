/*
 * JB16 16-bit arithmetic logic unit
 *
 * Combinational only: it has no clock and stores no values.
 */

`default_nettype none

module jb16_alu (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [3:0]  operation,
    output reg  [15:0] result,
    output reg         carry,
    output wire        zero,
    output wire        negative
);

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

    reg [16:0] extended_result;

    always @(*) begin
        result          = 16'h0000;
        carry           = 1'b0;
        extended_result = 17'h00000;

        case (operation)
            ALU_PASS_B: begin
                result = b;
            end

            ALU_ADD: begin
                extended_result = {1'b0, a} + {1'b0, b};
                result          = extended_result[15:0];
                carry           = extended_result[16];
            end

            ALU_SUB: begin
                result = a - b;
                // For subtraction, carry=1 means no unsigned borrow occurred.
                carry  = (a >= b);
            end

            ALU_AND: begin
                result = a & b;
            end

            ALU_OR: begin
                result = a | b;
            end

            ALU_XOR: begin
                result = a ^ b;
            end

            ALU_NOT: begin
                result = ~a;
            end

            ALU_SHL: begin
                result = {a[14:0], 1'b0};
                carry  = a[15];
            end

            ALU_SHR: begin
                result = {1'b0, a[15:1]};
                carry  = a[0];
            end

            ALU_INC: begin
                extended_result = {1'b0, a} + 17'h00001;
                result          = extended_result[15:0];
                carry           = extended_result[16];
            end

            ALU_DEC: begin
                result = a - 16'h0001;
                carry  = (a != 16'h0000);
            end

            default: begin
                result = 16'h0000;
                carry  = 1'b0;
            end
        endcase
    end

    assign zero     = (result == 16'h0000);
    assign negative = result[15];

endmodule

`default_nettype wire
