// Copyright 2018 Robert Balas <balasr@student.ethz.ch>
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Wrapper for a cv32e20 testbench, containing cv32e20, Memory and stdout peripheral
// Contributor: Robert Balas <balasr@student.ethz.ch>
// Module renamed from riscv_wrapper to cv32e20_tb_wrapper because (1) the
// name of the core changed, and (2) the design has a cv32e20_wrapper module.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-0.51
module riscof_cv32e20_tb_wrapper
  #(parameter INSTR_RDATA_WIDTH = 32,
    parameter RAM_ADDR_WIDTH    = 20,
    parameter BOOT_ADDR         = 32'h80,
    parameter DM_HALTADDRESS    = 32'h1A11_0800,
    parameter HART_ID           = 32'h00000000,
    parameter MHPMCounterNum    = 1,
    parameter MHPMCounterWidth  = 40
  )
  (input  logic         clk_i,
   input  logic         rst_ni,

   input  logic         fetch_enable_i,
   output logic         tests_passed_o,
   output logic         tests_failed_o,
   output logic [31:0]  exit_value_o,
   output logic         exit_valid_o);

  // Instruction interface
  logic                         instr_req;
  logic                         instr_gnt;
  logic                         instr_rvalid;
  logic [31:0]                  instr_addr;
  logic [31:0]                  instr_rdata;

  // Data interface
  logic                         data_req;
  logic                         data_gnt;
  logic                         data_rvalid;
  logic [31:0]                  data_addr;
  logic                         data_we;
  logic [3:0]                   data_be;
  logic [31:0]                  data_rdata;
  logic [31:0]                  data_wdata;

  // Debug and error
  logic                         debug_req;
  logic                         core_sleep_o;
  logic                         instr_err = 1'b0;
  logic                         data_err  = 1'b0;

  // Unused IRQs
  logic                         irq_software = 1'b0;
  logic                         irq_timer    = 1'b0;
  logic                         irq_external = 1'b0;
  logic [15:0]                  irq_fast     = '0;
  logic                         irq_nm       = 1'b0;

  // Instantiate CVE2 core
  cve2_top #(
    .MHPMCounterNum    (MHPMCounterNum),
    .MHPMCounterWidth  (MHPMCounterWidth),
  //  .RV32E             (1'b0),
  //  .RV32M (2'b01), // RV32MFast = 2'b01, from cve2_pkg
    .DmHaltAddr        (DM_HALTADDRESS),
    .DmExceptionAddr   (32'h1A110808)
  ) cve2_top_i (
    .clk_i             (clk_i),
    .rst_ni            (rst_ni),
    .test_en_i         (1'b0),        // disable clock gating for test
    .ram_cfg_i         ('0),          // dummy value for ram_cfg_i
    .hart_id_i         (HART_ID),
    .boot_addr_i       (BOOT_ADDR),

    .instr_req_o       (instr_req),
    .instr_gnt_i       (instr_gnt),
    .instr_rvalid_i    (instr_rvalid),
    .instr_addr_o      (instr_addr),
    .instr_rdata_i     (instr_rdata),
    .instr_err_i       (instr_err),

    .data_req_o        (data_req),
    .data_gnt_i        (data_gnt),
    .data_rvalid_i     (data_rvalid),
    .data_we_o         (data_we),
    .data_be_o         (data_be),
    .data_addr_o       (data_addr),
    .data_wdata_o      (data_wdata),
    .data_rdata_i      (data_rdata),
    .data_err_i        (data_err),

    .irq_software_i    (irq_software),
    .irq_timer_i       (irq_timer),
    .irq_external_i    (irq_external),
    .irq_fast_i        (irq_fast),
    .irq_nm_i          (irq_nm),

    .debug_req_i       (debug_req),
    .crash_dump_o      (),  // not used
    .fetch_enable_i    (fetch_enable_i),
    .core_sleep_o      (core_sleep_o)
  );

  // Instantiate RAM model
  mm_ram #(
    .RAM_ADDR_WIDTH     (RAM_ADDR_WIDTH),
    .INSTR_RDATA_WIDTH  (INSTR_RDATA_WIDTH)
  ) ram_i (
    .clk_i              (clk_i),
    .rst_ni             (rst_ni),
    .dm_halt_addr_i     (DM_HALTADDRESS),

    .instr_req_i        (instr_req),
    .instr_addr_i       ({ {10{1'b0}}, instr_addr[RAM_ADDR_WIDTH-1:0] }),
    .instr_rdata_o      (instr_rdata),
    .instr_rvalid_o     (instr_rvalid),
    .instr_gnt_o        (instr_gnt),

    .data_req_i         (data_req),
    .data_addr_i        (data_addr),
    .data_we_i          (data_we),
    .data_be_i          (data_be),
    .data_wdata_i       (data_wdata),
    .data_rdata_o       (data_rdata),
    .data_rvalid_o      (data_rvalid),
    .data_gnt_o         (data_gnt),

    .irq_id_i           (5'b0),
    .irq_ack_i          (1'b0),
    .irq_o              (),            // not used

    .debug_req_o        (debug_req),
    .pc_core_id_i       (32'h0),       // not exposed in cve2_top
    .tests_passed_o     (tests_passed_o),
    .tests_failed_o     (tests_failed_o),
    .exit_valid_o       (exit_valid_o),
    .exit_value_o       (exit_value_o)
  );

endmodule
