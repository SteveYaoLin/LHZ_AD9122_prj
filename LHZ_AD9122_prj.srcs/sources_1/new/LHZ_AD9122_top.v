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


module LHZ_AD9122_top(
    output [15:0] AD9122_data,
    input sys_clk,
    input sys_rst_n,
    input uart_rxd,
    output dac_data,
    output led,
    output ad9748_sleep,
    output pwm_port,
    output pwm_diff_port_n,
    output pwm_diff_port_p,
    output uart_txd
    );
endmodule
