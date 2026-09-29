//prevents creation of new wire if there is typo
`default_nettype none

module spi_peripheral (
    input  wire clk,       // chip's own clock
    input  wire rst_n,     // active-low reset

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

  reg sclk_sync0;
  reg sclk_sync1;
  reg sclk_sync2;
  reg copi_sync0;
  reg copi_sync1;
  reg ncs_sync0;
  reg ncs_sync1;
  reg ncs_sync2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sclk_sync0 <= 0; sclk_sync1 <= 0; sclk_sync2 <= 0;
      copi_sync0 <= 0; copi_sync1 <= 0;
      ncs_sync0  <= 1; ncs_sync1  <= 1; ncs_sync2 <= 1;
    end else begin
      sclk_sync0 <= sclk_raw;  sclk_sync1 <= sclk_sync0;  sclk_sync2 <= sclk_sync1;
      copi_sync0 <= copi_raw;  copi_sync1 <= copi_sync0;
      ncs_sync0  <= ncs_raw;   ncs_sync1  <= ncs_sync0;   ncs_sync2  <= ncs_sync1;
    end
  end

  wire sclk_posedge = (sclk_sync2 == 1'b0) && (sclk_sync1 == 1'b1);
  wire ncs_negedge  = (ncs_sync2  == 1'b1) && (ncs_sync1  == 1'b0);
  wire ncs_posedge  = (ncs_sync2  == 1'b0) && (ncs_sync1  == 1'b1);

  reg [15:0] shift_reg;
  reg [4:0]  bit_count;
  reg        transaction_ready;
  reg        transaction_processed;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg         <= 16'b0;
      bit_count         <= 5'b0;
      transaction_ready <= 1'b0;
    end else begin
      if (ncs_negedge) begin
        shift_reg <= 16'b0;
        bit_count <= 5'b0;
      end else if (ncs_sync1 == 1'b0 && sclk_posedge && bit_count < 16) begin
        shift_reg <= {shift_reg[14:0], copi_sync1};
        bit_count <= bit_count + 1;
      end

      if (ncs_posedge)
        transaction_ready <= 1'b1;
      else if (transaction_processed)
        transaction_ready <= 1'b0;
    end
  end

  wire       rw_bit  = shift_reg[15];
  wire [6:0] address = shift_reg[14:8];
  wire [7:0] data    = shift_reg[7:0];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      en_reg_out_7_0        <= 8'h00;
      en_reg_out_15_8       <= 8'h00;
      en_reg_pwm_7_0        <= 8'h00;
      en_reg_pwm_15_8       <= 8'h00;
      pwm_duty_cycle        <= 8'h00;
      transaction_processed <= 1'b0;
    end else if (transaction_ready && !transaction_processed) begin
      if (bit_count == 16 && rw_bit && address <= MAX_ADDRESS) begin
        case (address)
          7'h00: en_reg_out_7_0  <= data;
          7'h01: en_reg_out_15_8 <= data;
          7'h02: en_reg_pwm_7_0  <= data;
          7'h03: en_reg_pwm_15_8 <= data;
          7'h04: pwm_duty_cycle  <= data;
          default: ;
        endcase
      end
      transaction_processed <= 1'b1;
    end else if (!transaction_ready && transaction_processed) begin
      transaction_processed <= 1'b0;
    end
  end

endmodule