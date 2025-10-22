`timescale 1ns / 1ps

// Testbench for LHZ_AD9122_top
// - Clock/reset stimulus
// - Differential ad9516 clock (p/n)
// - UART sender tasks mirror those in tb_dds_sample_top
// - Simple uart_rx included to capture uart_txd from DUT

module tb_LHZ_AD9122_top();

// Parameters used by DUT (use defaults but declare for clarity)
localparam CLK_FREQ = 50000000;
localparam UART_BPS = 115200;
localparam SYS_CLK_PERIOD = 20; // ns -> 50 MHz
localparam BIT_PERIOD = 1_000_000_000 / UART_BPS; // ns per UART bit

// DUT connected signals
reg sys_clk;
reg sys_rst_n;
reg ad9516_clk_p;
reg ad9516_clk_n;
reg uart_rxd;
wire [7:0] dac_data; // default _DAC_WIDTH = 8
wire ad9748_sleep;
wire pwm_port;
wire pwm_diff_port_n;
wire pwm_diff_port_p;

wire ad9122_freme_p;
wire ad9122_freme_n;
wire ad9122_dci_p;
wire ad9122_dci_n;
wire ad9122_fpga_clk_p;
wire ad9122_fpga_clk_n;
wire [15:0] AD9122_data_p;
wire [15:0] AD9122_data_n;
wire ad9122_spi_sclk;
reg  ad9122_spi_sdio; // input to DUT
wire ad9122_spi_csn;
wire ad9122_spi_sdo;

wire ad9156_spi_sclk;
reg  ad9156_spi_sdio; // input to DUT
wire ad9156_spi_csn;
wire ad9156_spi_sdo;
reg  ad9516_irq;
wire ad9516_powerdown;
reg  ad9516_status;
reg  ad9516_lock_detect;
reg  ad9516_refmon;
wire ad9748_cken;

wire uart_txd;

// Instantiate DUT
LHZ_AD9122_top #(
    .CLK_FREQ(CLK_FREQ),
    .UART_BPS(UART_BPS)
) uut (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .ad9516_clk_p(ad9516_clk_p),
    .ad9516_clk_n(ad9516_clk_n),
    .uart_rxd(uart_rxd),
    .dac_data(dac_data),
    .ad9748_sleep(ad9748_sleep),
    .pwm_port(pwm_port),
    .pwm_diff_port_n(pwm_diff_port_n),
    .pwm_diff_port_p(pwm_diff_port_p),
    .ad9122_freme_p(ad9122_freme_p),
    .ad9122_freme_n(ad9122_freme_n),
    .ad9122_dci_p(ad9122_dci_p),
    .ad9122_dci_n(ad9122_dci_n),
    .ad9122_fpga_clk_p(ad9122_fpga_clk_p),
    .ad9122_fpga_clk_n(ad9122_fpga_clk_n),
    .AD9122_data_p(AD9122_data_p),
    .AD9122_data_n(AD9122_data_n),
    .ad9122_spi_sclk(ad9122_spi_sclk),
    .ad9122_spi_sdio(ad9122_spi_sdio),
    .ad9122_spi_csn(ad9122_spi_csn),
    .ad9122_spi_sdo(ad9122_spi_sdo),
    .ad9156_spi_sclk(ad9156_spi_sclk),
    .ad9156_spi_sdio(ad9156_spi_sdio),
    .ad9156_spi_csn(ad9156_spi_csn),
    .ad9156_spi_sdo(ad9156_spi_sdo),
    .ad9516_irq(ad9516_irq),
    .ad9516_powerdown(ad9516_powerdown),
    .ad9516_status(ad9516_status),
    .ad9516_lock_detect(ad9516_lock_detect),
    .ad9516_refmon(ad9516_refmon),
    .ad9748_cken(ad9748_cken),
    .uart_txd(uart_txd)
);

// Simple UART receiver to monitor uart_txd from DUT
wire rx_done;
wire [7:0] rx_data;

uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .UART_BPS(UART_BPS)
) u_rx (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .uart_rxd(uart_txd),
    .uart_rx_done(rx_done),
    .uart_rx_data(rx_data)
);

// Clock generation
initial sys_clk = 0;
always #(SYS_CLK_PERIOD/2) sys_clk = ~sys_clk;

// Generate differential ad9516 clock (p/n complementary)
initial begin
    ad9516_clk_p = 0;
    ad9516_clk_n = 1;
end
always #(SYS_CLK_PERIOD/2) begin
    ad9516_clk_p = ~ad9516_clk_p;
    ad9516_clk_n = ~ad9516_clk_n;
end

// Initial conditions
initial begin
    // defaults for inputs
    sys_rst_n = 0;
    uart_rxd = 1; // idle high
    ad9122_spi_sdio = 1'b1;
    ad9156_spi_sdio = 1'b1;
    ad9516_irq = 1'b0;
    ad9516_status = 1'b0;
    ad9516_lock_detect = 1'b0;
    ad9516_refmon = 1'b0;

    #100;
    sys_rst_n = 1; // release reset

    // wait for DUT internal clock wizard lock (observed in real DUT)
    #3000;

     #(BIT_PERIOD * 100);
     $display("[TB] Enable pwm5 slow pwm...");
     send_pwm_packet(8'h55,8'h02,8'h05,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h88,8'hAA);
    
    #(BIT_PERIOD * 200);
    $display("[TB] Enable pwm4 slow pwm...");
    send_pwm_packet(8'h55,8'h02,8'h04,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'he0,8'hAA);
    #4000500; // 等待 4.5ms
     #(BIT_PERIOD * 100);
     $display("[TB] disenable pwm5 slow pwm...");
     send_pwm_packet(8'h55,8'h02,8'h05,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hf1,8'hAA);

    
    // Run a sequence of UART packets that mirror tb_dds_sample_top
    
    #(BIT_PERIOD * 100);
    $display("[TB] disenable pwm4 slow pwm...");
    send_pwm_packet(8'h55,8'h02,8'h04,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h99,8'hAA);

    // #(BIT_PERIOD * 100);
    // $display("[TB] Sending configuration dac...");
    // send_pwm_packet(8'h55,8'h01,8'h02,8'h01,8'h01,8'h00,8'h02,8'h00,8'h00,8'h00,8'h00,8'h03,8'hfE,8'haa);

    // #(BIT_PERIOD * 100);
    // $display("[TB] Sending another config... ");
    // send_pwm_packet(8'h55,8'h02,8'h02,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h97,8'haa);

    // #(BIT_PERIOD * 100);
    // $display("[TB] Enable pwm1");
    // send_pwm_packet(8'h55,8'h01,8'h01,8'h01,8'h01,8'h00,8'h01,8'h00,8'h00,8'h00,8'h00,8'h01,8'h33,8'haa);

    // #(BIT_PERIOD * 100);
    // $display("[TB] Enable pwm1 act");
    // send_pwm_packet(8'h55,8'h02,8'h01,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h2f,8'haa);

    // #(BIT_PERIOD * 100);
    // $display("[TB] Enable pwm3 slow pwm");
    // send_pwm_packet(8'h55,8'h02,8'h03,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hff,8'hAA);

    // #(BIT_PERIOD * 100);
    // $display("[TB] Done. Stopping after short wait.");
    // #1000;
    // $stop;
end

// UART send helper (LSB first)
task uart_send_byte;
    input [7:0] data;
    integer i;
    begin
        // start bit
        uart_rxd = 1'b0;
        #BIT_PERIOD;
        for (i=0;i<8;i=i+1) begin
            uart_rxd = data[i];
            #BIT_PERIOD;
        end
        // stop bit
        uart_rxd = 1'b1;
        #BIT_PERIOD;
    end
endtask

// Send the multi-byte PWM packet used by firmware
task send_pwm_packet;
    input [7:0] header;
    input [7:0] reg_func;
    input [7:0] hs_pwm_ch;
    input [7:0] hs_ctrl_sta;
    input [7:0] duty_num;
    input [7:0] pulse_dessert_h;
    input [7:0] pulse_dessert_l;
    input [7:0] pulse_num;
    input [7:0] pat1;
    input [7:0] pat2;
    input [7:0] pat3;
    input [7:0] pat4;
    input [7:0] crc;
    input [7:0] footer;
    begin
        uart_send_byte(header);
        uart_send_byte(reg_func);
        uart_send_byte(hs_pwm_ch);
        uart_send_byte(hs_ctrl_sta);
        uart_send_byte(duty_num);
        uart_send_byte(pulse_dessert_h);
        uart_send_byte(pulse_dessert_l);
        uart_send_byte(pulse_num);
        uart_send_byte(pat1);
        uart_send_byte(pat2);
        uart_send_byte(pat3);
        uart_send_byte(pat4);
        uart_send_byte(crc);
        uart_send_byte(footer);
        #BIT_PERIOD;
        uart_rxd = 1'b1;
    end
endtask

// Optional: monitor the received bytes printed by monitor_rx_inst
always @(posedge rx_done) begin
    $display("[TB] DUT -> UART received byte: %02h at time %0t", rx_data, $time);
end

endmodule


// Reuse uart_rx implementation (same as in SAMPLE_DDS testbench) so TB is self-contained
module uart_rx(
    input               clk         ,
    input               rst_n       ,
    input               uart_rxd    ,
    output  reg         uart_rx_done,
    output  reg  [7:0]  uart_rx_data
    );

parameter CLK_FREQ = 50000000;
parameter UART_BPS = 115200;
localparam BAUD_CNT_MAX = CLK_FREQ / UART_BPS;

reg uart_rxd_d0;
reg uart_rxd_d1;
reg uart_rxd_d2;
reg rx_flag;
reg [3:0] rx_cnt;
reg [15:0] baud_cnt;
reg [7:0] rx_data_t;
wire start_en;

assign start_en = uart_rxd_d2 & (~uart_rxd_d1) & (~rx_flag);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        uart_rxd_d0 <= 1'b0;
        uart_rxd_d1 <= 1'b0;
        uart_rxd_d2 <= 1'b0;
    end else begin
        uart_rxd_d0 <= uart_rxd;
        uart_rxd_d1 <= uart_rxd_d0;
        uart_rxd_d2 <= uart_rxd_d1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rx_flag <= 1'b0;
    else if(start_en)
        rx_flag <= 1'b1;
    else if((rx_cnt == 4'd9) && (baud_cnt == BAUD_CNT_MAX/2 - 1'b1))
        rx_flag <= 1'b0;
    else
        rx_flag <= rx_flag;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        baud_cnt <= 16'd0;
    else if(rx_flag) begin
        if(baud_cnt < BAUD_CNT_MAX - 1'b1)
            baud_cnt <= baud_cnt + 16'b1;
        else
            baud_cnt <= 16'd0;
    end else
        baud_cnt <= 16'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rx_cnt <= 4'd0;
    else if(rx_flag) begin
        if(baud_cnt == BAUD_CNT_MAX - 1'b1)
            rx_cnt <= rx_cnt + 1'b1;
        else
            rx_cnt <= rx_cnt;
    end else
        rx_cnt <= 4'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rx_data_t <= 8'b0;
    else if(rx_flag) begin
        if(baud_cnt == BAUD_CNT_MAX/2 - 1'b1) begin
            case(rx_cnt)
                4'd1 : rx_data_t[0] <= uart_rxd_d2;
                4'd2 : rx_data_t[1] <= uart_rxd_d2;
                4'd3 : rx_data_t[2] <= uart_rxd_d2;
                4'd4 : rx_data_t[3] <= uart_rxd_d2;
                4'd5 : rx_data_t[4] <= uart_rxd_d2;
                4'd6 : rx_data_t[5] <= uart_rxd_d2;
                4'd7 : rx_data_t[6] <= uart_rxd_d2;
                4'd8 : rx_data_t[7] <= uart_rxd_d2;
                default : ;
            endcase
        end else
            rx_data_t <= rx_data_t;
    end else
        rx_data_t <= 8'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        uart_rx_done <= 1'b0;
        uart_rx_data <= 8'b0;
    end else if(rx_cnt == 4'd9 && baud_cnt == BAUD_CNT_MAX/2 - 1'b1) begin
        uart_rx_done <= 1'b1;
        uart_rx_data <= rx_data_t;
    end else begin
        uart_rx_done <= 1'b0;
        uart_rx_data <= uart_rx_data;
    end
end

endmodule
