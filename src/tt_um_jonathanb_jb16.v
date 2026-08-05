/*
 * Tiny Tapeout wrapper for JB16.
 *
 * The complete 16-bit CPU output is:
 *   {uio_out, uo_out}
 *
 * ui_in is the 8-bit value read by the IN instruction.
 */

`default_nettype none

module tt_um_jonathanb_jb16 (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire [15:0] cpu_output;

    jb16_cpu cpu (
        .clk(clk),
        .rst_n(rst_n),
        .enable(ena),
        .input_port(ui_in),
        .output_port(cpu_output)
    );

    // Low byte on the dedicated outputs, high byte on bidirectional outputs.
    assign uo_out  = cpu_output[7:0];
    assign uio_out = cpu_output[15:8];

    // All eight bidirectional pins are used as outputs.
    assign uio_oe = 8'hFF;

    // Keep the unused input path connected so lint does not report it floating.
    wire _unused = &{uio_in, 1'b0};

endmodule

`default_nettype wire
