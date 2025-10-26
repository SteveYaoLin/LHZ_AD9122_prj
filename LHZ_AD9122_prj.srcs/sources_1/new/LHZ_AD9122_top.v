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
    parameter _HALF_NUM_CLK4PRID = 50,               //
    parameter _PAT_WIDTH = 32 ,   // 
    parameter _NUM_CHANNELS = 3,        // 
    parameter _NUM_SLOW_CH = 3, 
    parameter CLK_FREQ = 50000000,               //
    parameter UART_BPS = 115200  ,                //
    parameter _DAC_WIDTH = 8      // 
)(
    input sys_clk,
    // input ad9516_clk_p,
    // input ad9516_clk_n,
    input uart_rxd,
    output [_DAC_WIDTH-1:0] dac_data,
//    output led,
    output ad9748_sleep,
    output pwm_slow_port,
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
    output      led_breath,
    output      ad9748_cken,
//    output      lt3471_enn,

    output uart_txd
);
// First, declare the necessary signals
wire clk_50M;
wire clk_100M;
wire clk_125M;
wire clk_500M;
wire locked;
wire resetn;
wire rst_n ; 
wire  [7:0] uart_data;
wire uart_done;
wire uart_get;
wire [7:0] pack_cnt;
wire pack_ing;
wire pack_done;
wire [7:0] pack_num;
wire recv_done;
wire [7:0] dataA;
wire [7:0] dataD;
wire [15:0] dataB;
wire [15:0] dataC;
wire led_enable;
// wire led_breath;
wire [(_NUM_CHANNELS + _NUM_SLOW_CH -1):0] pwm_out;
wire [_NUM_CHANNELS - 1:0] pwm_busy;
wire [_NUM_CHANNELS - 1:0] pwm_valid;

wire [7:0]     hs_pwm_ch     [_NUM_CHANNELS-1:0];
wire [7:0]     hs_ctrl_sta   [_NUM_CHANNELS-1:0];
wire [7:0]     duty_num      [_NUM_CHANNELS-1:0];
wire [16:0]    pulse_dessert [_NUM_CHANNELS-1:0];
wire [7:0]     pulse_num     [_NUM_CHANNELS-1:0];
wire [31:0]    PAT           [_NUM_CHANNELS-1:0];
wire [7:0]     ls_pwm_ch     [(_NUM_SLOW_CH -1):0];
wire [7:0]     ls_ctrl_sta   [(_NUM_CHANNELS + _NUM_SLOW_CH -1):0];

wire    [7:0]     rev_data0  ;
wire    [7:0]     rev_data1  ;
wire    [7:0]     rev_data2  ;
wire    [7:0]     rev_data3  ;
wire    [7:0]     rev_data4  ;
wire    [7:0]     rev_data5  ;
wire    [7:0]     rev_data6  ;
wire    [7:0]     rev_data7  ;
wire    [7:0]     rev_data8  ;
wire    [7:0]     rev_data9  ;
wire    [7:0]     rev_data10 ;
// wire    [7:0]     rev_data11 ;
wire [7:0] response_data; // Response data output

reg ad9516_upconf;
reg ad9516_upconf_d1;
reg ad9516_upconf_pulse;
// ������뻺������IBUFDS��
wire ad9516_clk_ibuf;
wire ad9122_dci;          // AD9122 DCI�ڲ��ź�
// �Զ����ɵ��ڲ��ź�
wire pwm_diff_port;        // PWM����ź��ڲ�����?
wire ad9122_freme;         // AD9122֡ͬ���ڲ�����
wire ad9122_fpga_clk;      // AD9122ʱ���ڲ�����
reg [15:0] reset_cnt = 0;      // ��λ�������ڲ��ź�
wire sys_rst_n ; // V5����û���ⲿ��λ�źţ�ֱ������
wire ad9616_finish; // AD5616��������ź�?
wire ad9516_lock; // AD9516�����ź�
wire dac_500M_clk;
wire dac_125M_clk;
wire AD9122_sda_dir;
//wire AD9122_sda_dir;
wire AD9122_sen_n;
wire ad9122_finish;
reg   ad9122_upconf_pulse;
always @(posedge sys_clk ) begin
    if (reset_cnt == 16'hffff) begin
        reset_cnt <= 16'hffff;
    end
    else begin
        reset_cnt <= reset_cnt + 1'b1;// led <= led_enable ? led_breath : 1'b0;
    end
end
assign sys_rst_n = (reset_cnt == 16'hffff) ? 1'b1 : 1'b0; // V5����û���ⲿ��λ�źţ�ֱ������
  clk_wiz_1 u_mmcm
  (
  // Clock out ports  
  .clk_out1(clk_50M),
  .clk_out2(clk_100M),
  .clk_out3(clk_125M),
  .clk_out4(clk_500M),
  // Status and control signals               
  .resetn(sys_rst_n), 
  .locked(locked),
 // Clock in ports
  .clk_in1(sys_clk)
  );
assign rst_n = sys_rst_n & locked; // Active low reset signal

// clk_wiz_1 u_dac
// (
//   // Clock out ports  
//   .clk_out1(dac_500M_clk),
//   .clk_out2(dac_125M_clk),
//   // Status and control signals               
//   .resetn(rst_n&&ad9616_finish), 
//   .locked(ad9516_lock),
//  // Clock in ports
//   .clk_in1_p(ad9122_fpga_clk_p),
//   .clk_in1_n(ad9122_fpga_clk_n)
//   );
// IBUFDS #(
//     .DIFF_TERM("FALSE"),    // δʹ�ò���ն�?
//     .IBUF_LOW_PWR("TRUE")   // �͹���ģʽ
// ) IBUFDS_ad9516_clk (
//     .O(ad9516_clk_ibuf),    // �������?
//     .I(ad9516_clk_p),       // ���������?
//     .IB(ad9516_clk_n)       // ��ָ�����?
// );

// ��������������OBUFDS��
OBUFDS OBUFDS_pwm_diff (
    .I(pwm_diff_port),      // �ڲ������ź�
    .O(pwm_diff_port_p),    // ��������
    .OB(pwm_diff_port_n)    // ��ָ����
);

// OBUFDS OBUFDS_ad9122_dci (
//     .I(ad9122_dci),      // �ڲ������ź�
//     .O(ad9122_dci_p),    // ��������
//     .OB(ad9122_dci_n)    // ��ָ����
// );

//OBUFDS OBUFDS_ad9122_freme (
//    .I(ad9122_freme),       // �ڲ������ź�
//    .O(ad9122_freme_p),     // ��������
//    .OB(ad9122_freme_n)     // ��ָ����
//);
assign ad9122_freme_p = 1'b0;
assign ad9122_freme_n = 1'b1;
OBUFDS OBUFDS_ad9122_fpga_clk (
    .I(1'b0),    // �ڲ������ź�
    .O(ad9122_fpga_clk_p),  // ��������
    .OB(ad9122_fpga_clk_n)  // ��ָ����
);



// // 16λ����������ߣ�OBUFDS��
// wire [15:0] AD9122_data;  // �ڲ���������
// genvar i;
// generate
//     for (i = 0; i < 16; i = i + 1) begin : AD9122_DATA_BUS
//         OBUFDS OBUFDS_ad9122_data (
//             .I(AD9122_data[i]),  // �ڲ���������
//             .O(AD9122_data_p[i]),    // ��������
//             .OB(AD9122_data_n[i])    // ��ָ����
//         );
//     end
// endgenerate
reg [15:0]dac1;
wire [31:0] data_out_from_device;
reg [15:0] cycle_cnt;
 always @(posedge clk_500M or negedge rst_n) begin
    if (!rst_n) begin
      dac1 <= 16'h7FFF;
      cycle_cnt <= 16'd0;
    end else begin
      if (cycle_cnt == (_HALF_NUM_CLK4PRID - 1)) begin
        cycle_cnt <= 16'd0;
        dac1 <= (dac1 == 16'h7FFF) ? 16'h8000 : 16'h7FFF;
      end else begin
        cycle_cnt <= cycle_cnt + 1;
      end
    end
  end
      // drive both upper and lower half with same dac1 value
  assign  data_out_from_device = {dac1, dac1};
//   assign  data_out_from_device = {16'h7FFF, 16'h7FFF};
  // Unit under test (keep parameters same as in design)
  selectio_tx #(.SYS_W(16), .DEV_W(32)) u_selectio_tx (
    .data_out_from_device(data_out_from_device),
    .data_out_to_pins_p(AD9122_data_p),
    .data_out_to_pins_n(AD9122_data_n),
    .clk_to_pins_p(ad9122_dci_p),
    .clk_to_pins_n(ad9122_dci_n),
    .clk_in(clk_500M),
    .clk_reset(!rst_n),
    .io_reset(!rst_n)
  );

OBUF #(
   .DRIVE(12),       // ����������Ϊ12mA�����ݸ��ص�����
   .IOSTANDARD("LVCMOS33"), // I/O��ƽ��׼
   .SLEW("SLOW")     // ѹ������ΪSLOW�Լ��ٸ�Ƶ��?????????????????
) OBUF_slow_sig (
   .O(pwm_slow_port),      // ʵ�����ţ�B35_L19_P?????????????????
//    .I(pwm_100khz)     // �����ź�����
   .I(pwm_out[_NUM_CHANNELS])      // ����ODDR����?????????????????
);

// assign ad9516_powerdown = pwm_out[5]; // ����AD9516���������ģ�?
assign ad9516_powerdown = 1'b1; // ����AD9516���������ģ�?
assign ad9748_cken = 1'b1; // ����AD9748ʱ��ʹ��

wire upon_config;
// reg pwm_out_upconf      ;    
// reg pwm_out_upconf_d1   ;
// reg pwm_out_upconf_pulse;
always @(posedge clk_50M or negedge rst_n) begin
    if (!rst_n) begin
        ad9516_upconf       <= 1'b0;
        ad9516_upconf_d1    <= 1'b0;
        ad9516_upconf_pulse <= 1'b0;
    end 
    else begin
        ad9516_upconf <= pwm_out[4]; // ��pwm_out[4]�������źţ�����AD9516������Ϣ
        ad9516_upconf_d1 <= ad9516_upconf;
        if (!ad9516_upconf_d1 && ad9516_upconf) begin
            ad9516_upconf_pulse <= 1'b1;// �����ش����������߼����û��ɸ������󲹳䣩
        end
        else begin
            ad9516_upconf_pulse <= 1'b0;
        end
    end
end

// wire slow_conf;
// always @(posedge clk_50M or negedge rst_n) begin
//     if (!rst_n) begin
//         pwm_out_upconf <= 1'b0;
//         pwm_out_upconf_d1 <= 1'b0;
//         pwm_out_upconf_pulse <= 1'b0;
//     end 
//     else begin
//         pwm_out_upconf <= pwm_out[4]; // ��pwm_out[4]�������źţ�����AD9516������Ϣ
//         pwm_out_upconf_d1 <= pwm_out_upconf;
//         if (!pwm_out_upconf_d1 && pwm_out_upconf) begin
//             pwm_out_upconf_pulse <= 1'b1;// �����ش����������߼����û��ɸ������󲹳䣩
//         end
//         else begin
//             pwm_out_upconf_pulse <= 1'b0;
//         end
//     end
// end

reg [11:0] pwm_counter = 0;


    always @(posedge clk_50M or negedge rst_n) begin
            if (!rst_n) begin
                pwm_counter <= 12'd0;
            end
            else if (pwm_counter == 12'd2047) begin
                pwm_counter <= pwm_counter;
                // pwm_100khz <= ~pwm_100khz;
            end
            else begin
                pwm_counter <= pwm_counter + 8'd1;
            end
    end
assign upon_config = (pwm_counter[11:1] == 11'h3f4) ? 1'b1 : 1'b0;

// Then, instantiate the module with proper port connections
uart_mult_byte_rx #(
    .CLK_FREQ(CLK_FREQ),
    .UART_BPS(UART_BPS)
) u_uart_rx_inst (
    .sys_clk    (clk_50M),      // Connect to input clock
    .sys_rst_n  (!rst_n  ),    // Connect to reset
    .uart_rxd   (uart_rxd),     // Connect to UART RX input
    
    .uart_data  (uart_data),    // Connect to internal signal
    .uart_done  (uart_done),    // Connect to internal signal
    .uart_get   (uart_get),     // Connect to internal signal
    
    .pack_cnt   (pack_cnt),     // Connect to internal signal
    .pack_ing   (pack_ing),     // Connect to internal signal
    .pack_done_d1  (pack_done),    // Connect to internal signal
    .pack_num   (pack_num),     // Connect to internal signal
    .recv_done  (recv_done),    // Connect to internal signal
    
    .rev_data0  (rev_data0   ),
    .rev_data1  (rev_data1   ),
    .rev_data2  (rev_data2   ),
    .rev_data3  (rev_data3   ),
    .rev_data4  (rev_data4   ),
    .rev_data5  (rev_data5   ),
    .rev_data6  (rev_data6   ),
    .rev_data7  (rev_data7   ),
    .rev_data8  (rev_data8   ),
    .rev_data9  (rev_data9   ),
    .rev_data10 (rev_data10  ),
    .response_data(response_data)
    // .rev_data11 (rev_data11  ) 
    // .hs_pwm_ch    (hs_pwm_ch    ),
	// .hs_ctrl_sta  (hs_ctrl_sta  ),
	// .duty_num     (duty_num     ),
	// .pulse_dessert(pulse_dessert),
	// .pulse_num    (pulse_num    ),
	// .PAT          (PAT          ),
	// .ls_pwm_ch    (ls_pwm_ch    ),
	// .ls_ctrl_sta  (ls_ctrl_sta  )
);

uart_reg_mapper # (
    ._NUM_CHANNELS(_NUM_CHANNELS),
    ._NUM_SLOW_CH(_NUM_SLOW_CH)
)u_uart_reg_mapper(
   /*input wire  */.clk_50M    (clk_50M) ,      // 50MHzʱ������
   /*input wire  */.clk_100M   (clk_100M) ,     // 100MHzʱ������
   /*input wire  */.rst_n      (rst_n  ) ,
   // UART�ӿ��ź�
   /*input [7:0] */  .func_reg    (rev_data0   ) ,
   /*input [7:0] */  .rev_data1   (rev_data1   ) ,
   /*input [7:0] */  .rev_data2   (rev_data2   ) ,
   /*input [7:0] */  .rev_data3   (rev_data3   ) ,
   /*input [7:0] */  .rev_data4   (rev_data4   ) ,
   /*input [7:0] */  .rev_data5   (rev_data5   ) ,
   /*input [7:0] */  .rev_data6   (rev_data6   ) ,
   /*input [7:0] */  .rev_data7   (rev_data7   ) ,
   /*input [7:0] */  .rev_data8   (rev_data8   ) ,
   /*input [7:0] */  .rev_data9   (rev_data9   ) ,
   /*input [7:0] */  .rev_data10  (rev_data10  ) ,
//    /*input [7:0] */  .rev_data11  (rev_data11  ) ,
   /*input       */  .pack_done   (pack_done   ) ,     // ���ݰ�������ɱ�????????????
   
   // PWMͨ���ӿ�
   /*output [7:0]  .hs_ctrl_sta   (hs_ctrl_sta  ), */
   /*output [7:0]  .duty_num      (duty_num     ), */
   /*output [15:0] .pulse_dessert (pulse_dessert), */
   /*output [7:0]  .pulse_num     (pulse_num    ), */
   /*output [31:0] .PAT           (PAT          ), */
   /*output [7:0]  .ls_ctrl_sta   (ls_ctrl_sta  ), */
   /*output [7:0]  .hs_pwm_ch     (hs_pwm_ch    ), */
   /*output [7:0]  .ls_pwm_ch     (ls_pwm_ch    )  */          
   /*output wire [_DAC_WIDTH - 1:0 ]*/.dac_data (dac_data ),         
   /*output wire [_NUM_CHANNELS-1:0]*/.pwm_out  (pwm_out  ),    // PWM�������?
   /*output wire [_NUM_CHANNELS-1:0]*/.pwm_busy (pwm_busy ),   // æ״̬???��
   /*output wire [_NUM_CHANNELS-1:0]*/.pwm_valid(pwm_valid)   // ��Ч��־����
);
uart_protocol_tx #(
    .CLK_FREQ(CLK_FREQ),
    .UART_BPS(UART_BPS) // Define the UART baud rate
    )
    u_uart_protocol_tx(
    /*input       */.clk_50M  (clk_50M  ),
    /*input       */.rst_n    (rst_n    ),
                                //8'h80;
    /*input       */.recv_done(recv_done),
    /*input [7:0] */.rev_data0(rev_data0),
    /*input [7:0] */.rev_data1(rev_data1),
    /*input [7:0] */.rev_data2(rev_data2),
    /*input [7:0] */.rev_data3(rev_data3),
                    .rev_data4   (rev_data4   ) ,
                    .rev_data5   (rev_data5   ) ,
                    .rev_data6   (rev_data6   ) ,
                    .rev_data7   (rev_data7   ) ,
                    .rev_data8   (rev_data8   ) ,
                    .rev_data9   (rev_data9   ) ,
                    .rev_data10  (rev_data10  ) ,
                    .response_data(response_data),
                            //uart_tx_crc8
    /*output      */.uart_txd (uart_txd )
    );

     // instantiate DUT
  ad9516_spi_wr_config ad9516_config (
    .clk_in(clk_50M),
    .rst_n(rst_n),
    .o_sclk(ad9156_spi_sclk),
    .o_sda(ad9156_spi_sdo),
    .o_cs_n(ad9156_spi_csn),
    .o_adk_rst(),
    //  .datain_valid(upon_config||ad9516_upconf_pulse),
   .datain_valid(upon_config),
    .datain_ready(ad9616_finish)
  );
  // helpers for edge detect and pulse generation
reg ad9616_finish_d1; // delayed version of ad9616_finish
reg [1:0] ad9122_pulse_cnt; // remaining cycles for pulse (2..0)

// Generate ad9122_upconf_pulse when ad9616_finish rises: pulse for exactly 2 clk_50M cycles
always @(posedge clk_50M or negedge rst_n) begin
    if (!rst_n) begin
        ad9616_finish_d1 <= 1'b0;
        ad9122_pulse_cnt <= 2'd0;
        ad9122_upconf_pulse <= 1'b0;
    end else begin
        ad9616_finish_d1 <= ad9616_finish;
        // detect rising edge
        if (ad9616_finish && !ad9616_finish_d1) begin
            ad9122_pulse_cnt <= 2'd2; // start counter (2 cycles)
            ad9122_upconf_pulse <= 1'b1;
        end else if (ad9122_pulse_cnt != 2'd0) begin
            // decrement counter each clk_50M cycle
            ad9122_pulse_cnt <= ad9122_pulse_cnt - 1'b1;
            // Keep pulse high while counter > 1
            ad9122_upconf_pulse <= (ad9122_pulse_cnt > 2'd1) ? 1'b1 : 1'b0;
        end else begin
            ad9122_upconf_pulse <= 1'b0;
        end
    end
end
// config ad9122
ad9122_spi_wr_config ad9122_config(
    /*input  */.clk_in          (clk_50M),
    /*input  */.rst_n           (rst_n),
    /*output */.o_sclk          (ad9122_spi_sclk),
    /*output */.o_sda           (ad9122_spi_sdo),
    /*output */.o_sda_dir       (AD9122_sda_dir),
    /*output */.o_sen_n         (ad9122_spi_csn),
    /*output */.o_reset         (),
    /*input  */.io_sda          (ad9122_spi_sdio),
    /*input  */.datain_valid    (ad9516_upconf_pulse),
    /*output */.datain_ready    (ad9122_finish) 
                        ); 

   assign ad9748_sleep = 1'b1; // ʹ��AD9748����
// ����ԭ���ڲ��ź��������������󲹳䣩
// wire [15:0] AD9122_data;
// ... �����ڲ��߼��ź�

// ģ��ʵ�ʹ����߼����˴����û����䣩
// ע�⣺���в�ֶ˿�����ͨ���ڲ������ź�����?
// ���磺
//   assign pwm_diff_port = ...;
//   assign ad9122_freme = ...;
//   assign ad9122_fpga_clk = ...;
breath_led u_breath_led(
    .sys_clk         (clk_125M) ,      //
    .sys_rst_n       (rst_n) ,    //
    .led (led_breath )           //
);
wire test1 ;
wire test2 ;
wire test3 ;
wire test4 ;
assign test1 = pwm_out[3];
assign test2 = pwm_out[4];
assign test3 = pwm_out[5];
//  ila_0 u_ila_1(
//  .clk	(clk_50M),
//  .probe0	(rev_data3),
//  .probe1	(rev_data0),
//  .probe2	(rev_data1),
//  .probe3	({upon_config,ad9516_upconf_pulse,test2,test3}),
//  .probe4	(rev_data4),
//  .probe5	(rev_data2),
//  .probe6	(pack_cnt),
//  .probe7	({test1,ad9156_spi_sclk,ad9156_spi_sdo,ad9156_spi_csn,uart_txd,uart_rxd,pack_done,recv_done})
//  );
endmodule
