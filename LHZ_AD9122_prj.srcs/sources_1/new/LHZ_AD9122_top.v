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

// ������뻺������IBUFDS��
wire ad9516_clk_ibuf;
wire ad9122_dci;          // AD9122 DCI�ڲ��ź�
// �Զ����ɵ��ڲ��ź�
wire pwm_diff_port;        // PWM����ź��ڲ�����
wire ad9122_freme;         // AD9122֡ͬ���ڲ�����
wire ad9122_fpga_clk;      // AD9122ʱ���ڲ�����
IBUFDS #(
    .DIFF_TERM("FALSE"),    // δʹ�ò���ն�
    .IBUF_LOW_PWR("TRUE")   // �͹���ģʽ
) IBUFDS_ad9516_clk (
    .O(ad9516_clk_ibuf),    // �������
    .I(ad9516_clk_p),       // ���������
    .IB(ad9516_clk_n)       // ��ָ�����
);

// ��������������OBUFDS��
OBUFDS OBUFDS_pwm_diff (
    .I(pwm_diff_port),      // �ڲ������ź�
    .O(pwm_diff_port_p),    // ��������
    .OB(pwm_diff_port_n)    // ��ָ����
);

OBUFDS OBUFDS_ad9122_dci (
    .I(ad9122_dci),      // �ڲ������ź�
    .O(ad9122_dci_p),    // ��������
    .OB(ad9122_dci_n)    // ��ָ����
);

OBUFDS OBUFDS_ad9122_freme (
    .I(ad9122_freme),       // �ڲ������ź�
    .O(ad9122_freme_p),     // ��������
    .OB(ad9122_freme_n)     // ��ָ����
);

OBUFDS OBUFDS_ad9122_fpga_clk (
    .I(ad9122_fpga_clk),    // �ڲ������ź�
    .O(ad9122_fpga_clk_p),  // ��������
    .OB(ad9122_fpga_clk_n)  // ��ָ����
);



// 16λ����������ߣ�OBUFDS��
wire [15:0] AD9122_data;  // �ڲ���������
genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin : AD9122_DATA_BUS
        OBUFDS OBUFDS_ad9122_data (
            .I(AD9122_data[i]),  // �ڲ���������
            .O(AD9122_data_p[i]),    // ��������
            .OB(AD9122_data_n[i])    // ��ָ����
        );
    end
endgenerate
// ����ԭ���ڲ��ź��������������󲹳䣩
// wire [15:0] AD9122_data;
// ... �����ڲ��߼��ź�

// ģ��ʵ�ʹ����߼����˴����û����䣩
// ע�⣺���в�ֶ˿�����ͨ���ڲ������ź�����
// ���磺
//   assign pwm_diff_port = ...;
//   assign ad9122_freme = ...;
//   assign ad9122_fpga_clk = ...;

endmodule
