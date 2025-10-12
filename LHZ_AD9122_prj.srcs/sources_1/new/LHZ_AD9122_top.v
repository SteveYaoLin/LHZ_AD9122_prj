`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/10 22:57:27
// Design Name: 
// Module Name: LHZ_AD9122_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module LHZ_AD9122_top
# (
    parameter _PAT_WIDTH = 32 ,   // 
    parameter _NUM_CHANNELS = 3,        // 
    parameter _NUM_SLOW_CH = 1, 
    parameter CLK_FREQ = 50000000,               //
    parameter UART_BPS = 115200  ,                //
    parameter _DAC_WIDTH = 8      // 
)(
    input sys_clk,
    input sys_rst_n,
    input ad9516_clk_p,
    input ad9516_clk_n,
    input uart_rxd,
    output [_DAC_WIDTH-1:0] dac_data,
//    output led,
    output ad9748_sleep,
    output pwm_port,
    output pwm_diff_port_n,
    output pwm_diff_port_p,
    /* AD9122 */
    output      ad9122_freme_p,
    output      ad9122_freme_n,
    output      ad9122_dci_p,
    output      ad9122_dci_n,
    output      ad9122_fpga_clk_p,
    output      ad9122_fpga_clk_n,
    output [15:0] AD9122_data_p,
    output [15:0] AD9122_data_n,
    output      ad9122_spi_sclk,
    input       ad9122_spi_sdio,
    output      ad9122_spi_csn,
    output      ad9122_spi_sdo,
    /*AD9516*/
    output      ad9156_spi_sclk,
    input       ad9156_spi_sdio,
    output      ad9156_spi_csn,
    output      ad9156_spi_sdo,
    input       ad9516_irq,
    output      ad9516_powerdown,
    input       ad9516_status,
    input       ad9516_lock_detect,
    input       ad9516_refmon,

    output      ad9748_cken,
//    output      lt3471_enn,

    output uart_txd
);

// 差分输入缓冲器（IBUFDS）
wire ad9516_clk_ibuf;
wire ad9122_dci;          // AD9122 DCI内部信号
// 自动生成的内部信号
wire pwm_diff_port;        // PWM差分信号内部驱动
wire ad9122_freme;         // AD9122帧同步内部驱动
wire ad9122_fpga_clk;      // AD9122时钟内部驱动
IBUFDS #(
    .DIFF_TERM("FALSE"),    // 未使用差分终端
    .IBUF_LOW_PWR("TRUE")   // 低功耗模式
) IBUFDS_ad9516_clk (
    .O(ad9516_clk_ibuf),    // 缓冲输出
    .I(ad9516_clk_p),       // 差分正输入
    .IB(ad9516_clk_n)       // 差分负输入
);

// 差分输出缓冲器（OBUFDS）
OBUFDS OBUFDS_pwm_diff (
    .I(pwm_diff_port),      // 内部单端信号
    .O(pwm_diff_port_p),    // 差分正输出
    .OB(pwm_diff_port_n)    // 差分负输出
);

OBUFDS OBUFDS_ad9122_dci (
    .I(ad9122_dci),      // 内部单端信号
    .O(ad9122_dci_p),    // 差分正输出
    .OB(ad9122_dci_n)    // 差分负输出
);

OBUFDS OBUFDS_ad9122_freme (
    .I(ad9122_freme),       // 内部单端信号
    .O(ad9122_freme_p),     // 差分正输出
    .OB(ad9122_freme_n)     // 差分负输出
);

OBUFDS OBUFDS_ad9122_fpga_clk (
    .I(ad9122_fpga_clk),    // 内部单端信号
    .O(ad9122_fpga_clk_p),  // 差分正输出
    .OB(ad9122_fpga_clk_n)  // 差分负输出
);



// 16位差分数据总线（OBUFDS）
wire [15:0] AD9122_data;  // 内部数据总线
genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin : AD9122_DATA_BUS
        OBUFDS OBUFDS_ad9122_data (
            .I(AD9122_data[i]),  // 内部单端数据
            .O(AD9122_data_p[i]),    // 差分正输出
            .OB(AD9122_data_n[i])    // 差分负输出
        );
    end
endgenerate
// 其他原有内部信号声明（根据需求补充）
// wire [15:0] AD9122_data;
// ... 其他内部逻辑信号

// 模块实际功能逻辑（此处需用户补充）
// 注意：所有差分端口现在通过内部单端信号驱动
// 例如：
//   assign pwm_diff_port = ...;
//   assign ad9122_freme = ...;
//   assign ad9122_fpga_clk = ...;

endmodule
