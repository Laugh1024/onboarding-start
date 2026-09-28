module spi_peripheral (
    input  wire clk,
    input  wire rst_n,

    input  wire sclk_raw,
    input  wire copi_raw,
    input  wire ncs_raw,

    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

  localparam MAX_ADDRESS = 7'h04;

  reg sclk_sync0, sclk_sync1, sclk_sync2;
  reg copi_sync0, copi_sync1;
  reg ncs_sync0,  ncs_sync1,  ncs_sync2;   // nCS now has 3 stages too

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sclk_sync0 <= 0; sclk_sync1 <= 0; sclk_sync2 <= 0;
      copi_sync0 <= 0; copi_sync1 <= 0;
      ncs_sync0  <= 1; ncs_sync1  <= 1; ncs_sync2 <= 1;  // nCS idles high
    end else begin
      sclk_sync0 <= sclk_raw;  sclk_sync1 <= sclk_sync0;  sclk_sync2 <= sclk_sync1;
      copi_sync0 <= copi_raw;  copi_sync1 <= copi_sync0;
      ncs_sync0  <= ncs_raw;   ncs_sync1  <= ncs_sync0;   ncs_sync2  <= ncs_sync1;
    end
  end

  // Edge detection
  wire sclk_posedge = (sclk_sync2 == 1'b0) && (sclk_sync1 == 1'b1);
  wire ncs_negedge  = (ncs_sync2  == 1'b1) && (ncs_sync1  == 1'b0);  // transaction starts
  wire ncs_posedge  = (ncs_sync2  == 1'b0) && (ncs_sync1  == 1'b1);  // transaction ends

endmodule