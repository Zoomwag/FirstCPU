`timescale 1ns/1ps
`default_nettype none

// Jonathan's testbench top-level module is deliberately named "test".
module test;

    reg        clk;
    reg        rst_n;
    reg        ena;
    reg [7:0]  ui_in;
    reg [7:0]  uio_in;

    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    wire [15:0] output_word;

    integer errors;

    assign output_word = {uio_out, uo_out};

    tt_um_jonathanb_jb16 dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    initial begin
        clk = 1'b0;
    end

    always begin
        #5 clk = ~clk;
    end

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task expect_output;
        input [15:0] expected;
        begin
            if (output_word !== expected) begin
                $display("FAILED: expected output %h, got %h", expected, output_word);
                errors = errors + 1;
            end else begin
                $display("PASSED: output = %h", output_word);
            end
        end
    endtask

    initial begin
        $dumpfile("jb16.vcd");
        $dumpvars(0, test);

        errors = 0;
        ena    = 1'b1;
        ui_in  = 8'h00;
        uio_in = 8'h00;
        rst_n  = 1'b0;

        // Hold reset for two clock edges.
        repeat (2) tick;
        rst_n = 1'b1;

        // LDI 3, OUT
        repeat (2) tick;
        expect_output(16'h0003);

        // DEC, JNZ, OUT
        repeat (3) tick;
        expect_output(16'h0002);

        repeat (3) tick;
        expect_output(16'h0001);

        // Finish loop, build AA55, store it, reload it and output it.
        repeat (8) tick;
        expect_output(16'hAA55);

        // IN 2A, ADDI 1, OUT -> 002B.
        ui_in = 8'h2A;
        repeat (3) tick;
        expect_output(16'h002B);

        // Loop back, then IN FF, ADDI 1, OUT -> 0100.
        ui_in = 8'hFF;
        repeat (4) tick;
        expect_output(16'h0100);

        // ena=0 must freeze the CPU.
        ena   = 1'b0;
        ui_in = 8'h00;
        repeat (4) tick;
        expect_output(16'h0100);

        // Resume: JMP, IN 00, ADDI 1, OUT -> 0001.
        ena = 1'b1;
        repeat (4) tick;
        expect_output(16'h0001);

        if (uio_oe !== 8'hFF) begin
            $display("FAILED: uio_oe should be FF, got %h", uio_oe);
            errors = errors + 1;
        end

        // Asynchronous active-low reset should immediately clear the output.
        rst_n = 1'b0;
        #1;
        expect_output(16'h0000);

        if (errors == 0) begin
            $display("");
            $display("ALL JB16 TESTS PASSED!");
        end else begin
            $display("");
            $display("%0d JB16 TESTS FAILED", errors);
        end

        $finish;
    end

endmodule

`default_nettype wire
