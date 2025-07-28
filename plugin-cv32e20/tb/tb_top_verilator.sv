// Copyright 2018 Robert Balas <balasr@student.ethz.ch>
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Top level wrapper for a verilator CV32E20 testbench

module tb_top_verilator #(
    parameter INSTR_RDATA_WIDTH = 128,
    parameter RAM_ADDR_WIDTH    =  22,
    parameter BOOT_ADDR         = 'h80
)(
    input  logic clk_i,
    input  logic rst_ni,
    input  logic fetch_enable_i,
    output logic tests_passed_o,
    output logic tests_failed_o
);

    // cycle counter
    int unsigned cycle_cnt_q;

    // testbench result
    logic        exit_valid;
    logic [31:0] exit_value;

    // Load firmware into RAM
    initial begin: load_prog
        automatic logic [1023:0] firmware;

        if ($value$plusargs("firmware=%s", firmware)) begin
            if ($test$plusargs("verbose"))
                $display("[TESTBENCH] %t: loading firmware %0s ...", $time, firmware);
            $readmemh(firmware, cv32e20_tb_wrapper_i.ram_i.dp_ram_i.mem);
        end else begin
            $display("No firmware specified");
            $finish;
        end
    end

    // Abort after maxcycles if given
    always_ff @(posedge clk_i, negedge rst_ni) begin
        automatic int maxcycles;
        if ($value$plusargs("maxcycles=%d", maxcycles)) begin
            if (~rst_ni) begin
                cycle_cnt_q <= 0;
            end else begin
                cycle_cnt_q <= cycle_cnt_q + 1;
                if (cycle_cnt_q >= maxcycles) begin
                    $finish("Simulation aborted due to maximum cycle limit");
                end
            end
        end
    end

    // Monitor for success/failure
    always_ff @(posedge clk_i, negedge rst_ni) begin: catch_exit
        integer cnt;
        if (!rst_ni) begin
            cnt = 0;
        end else begin
            if (!(++cnt % 10_000)) $display("%m @ %0t: tick", $time);
            if (cnt >= 20_000) $finish;

            if (tests_passed_o) begin
                $display("%m @ %0t: ALL TESTS PASSED", $time);
                $finish;
            end
            if (tests_failed_o) begin
                $display("%m @ %0t: TEST(S) FAILED!", $time);
                $finish;
            end
            if (exit_valid) begin
                if (exit_value == 0)
                    $display("%m @ %0t: EXIT SUCCESS", $time);
                else
                    $display("%m @ %0t: EXIT FAILURE: %d", $time, exit_value);
                $finish;
            end
        end
    end

    // Instantiated wrapper (renamed and updated)
    riscof_cv32e20_tb_wrapper
        #(
            .INSTR_RDATA_WIDTH (INSTR_RDATA_WIDTH),
            .RAM_ADDR_WIDTH    (RAM_ADDR_WIDTH),
            .BOOT_ADDR         (BOOT_ADDR)
        ) cv32e20_tb_wrapper_i (
            .clk_i          (clk_i),
            .rst_ni         (rst_ni),
            .fetch_enable_i (fetch_enable_i),
            .tests_passed_o (tests_passed_o),
            .tests_failed_o (tests_failed_o),
            .exit_valid_o   (exit_valid),
            .exit_value_o   (exit_value)
        );

endmodule

