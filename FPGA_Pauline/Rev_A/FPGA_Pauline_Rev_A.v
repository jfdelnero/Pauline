//-------------------------------------------------------------------------------
//------------H----H--X----X-----CCCCC-----22222----0000-----0000-----11---------
//-----------H----H----X-X-----C--------------2---0----0---0----0---1-1----------
//----------HHHHHH-----X------C----------22222---0----0---0----0-----1-----------
//---------H----H----X--X----C----------2-------0----0---0----0-----1------------
//--------H----H---X-----X---CCCCC-----22222----0000-----0000----11111-----------
//-------------------------------------------------------------------------------
//------- Contact: hxc2001 at hxc2001.com ----------- https://hxc2001.com -------
//------- (c) 2019-2020 Jean-François DEL NERO ----------------------------------
//--============================================================================-
//-- Pauline
//-- Disk archiving and Floppy disk drive simulator system.
//--
//-- https://hxc2001.com
//-- HxC2001   -   2019 - 2020
//--
//-- Design units   :
//--
//-- File name      : FPGA_Pauline_Rev_A.v
//--
//-- Purpose        : Top level 
//--
//--============================================================================-
//-- Revision list
//-- Version   Author                 Date                        Changes
//--
//-- 1.0    Jean-François DEL NERO  20 April 2019          First version
//--------------------------------------------------------------------------------

module FPGA_Pauline_Rev_A(

    //////////// CLOCK //////////
    input               FPGA_CLK1_50,
    input               FPGA_CLK2_50,
    input               FPGA_CLK3_50,

    //////////// HDMI //////////
    inout               HDMI_I2C_SCL,
    inout               HDMI_I2C_SDA,
    inout               HDMI_I2S,
    inout               HDMI_LRCLK,
    inout               HDMI_MCLK,
    inout               HDMI_SCLK,
    output              HDMI_TX_CLK,
    output   [23: 0]    HDMI_TX_D,
    output              HDMI_TX_DE,
    output              HDMI_TX_HS,
    input               HDMI_TX_INT,
    output              HDMI_TX_VS,

    //////////// HPS //////////
    inout               HPS_CONV_USB_N,
    output   [14: 0]    HPS_DDR3_ADDR,
    output   [ 2: 0]    HPS_DDR3_BA,
    output              HPS_DDR3_CAS_N,
    output              HPS_DDR3_CK_N,
    output              HPS_DDR3_CK_P,
    output              HPS_DDR3_CKE,
    output              HPS_DDR3_CS_N,
    output   [ 3: 0]    HPS_DDR3_DM,
    inout    [31: 0]    HPS_DDR3_DQ,
    inout    [ 3: 0]    HPS_DDR3_DQS_N,
    inout    [ 3: 0]    HPS_DDR3_DQS_P,
    output              HPS_DDR3_ODT,
    output              HPS_DDR3_RAS_N,
    output              HPS_DDR3_RESET_N,
    input               HPS_DDR3_RZQ,
    output              HPS_DDR3_WE_N,
    output              HPS_ENET_GTX_CLK,
    inout               HPS_ENET_INT_N,
    output              HPS_ENET_MDC,
    inout               HPS_ENET_MDIO,
    input               HPS_ENET_RX_CLK,
    input    [ 3: 0]    HPS_ENET_RX_DATA,
    input               HPS_ENET_RX_DV,
    output   [ 3: 0]    HPS_ENET_TX_DATA,
    output              HPS_ENET_TX_EN,
    inout               HPS_GSENSOR_INT,
    inout               HPS_I2C0_SCLK,
    inout               HPS_I2C0_SDAT,
    inout               HPS_I2C1_SCLK,
    inout               HPS_I2C1_SDAT,
    inout               HPS_KEY,
    inout               HPS_LED,
    inout               HPS_LTC_GPIO,
    output              HPS_SD_CLK,
    inout               HPS_SD_CMD,
    inout    [ 3: 0]    HPS_SD_DATA,
    output              HPS_SPIM_CLK,
    input               HPS_SPIM_MISO,
    output              HPS_SPIM_MOSI,
    inout               HPS_SPIM_SS,
    input               HPS_UART_RX,
    output              HPS_UART_TX,
    input               HPS_USB_CLKOUT,
    inout    [ 7: 0]    HPS_USB_DATA,
    input               HPS_USB_DIR,
    input               HPS_USB_NXT,
    output              HPS_USB_STP,

    //////////// KEY //////////
    input    [ 1: 0]    KEY,

    //////////// LED //////////
    output   [ 7: 0]    LED,

    //////////// GPIOS //////////
    inout   [ 35: 0]   GPIO0,
    inout   [ 35: 0]   GPIO1,

	inout   [ 7: 0]    GPIO_JP3,

    //////////// SW //////////
    input    [ 3: 0]    SW
);



//=======================================================
//  REG/WIRE declarations
//=======================================================
wire hps_fpga_reset_n;
wire     [1: 0]     fpga_debounced_buttons;
wire     [6: 0]     fpga_led_internal;
wire     [7: 0]     fpga_led_test;
wire     [2: 0]     hps_reset_req;
wire                hps_cold_reset;
wire                hps_warm_reset;
wire                hps_debug_reset;
wire     [27: 0]    stm_hw_events;
wire                fpga_clk_50;

wire     [3: 0]     led1_out;
wire     [3: 0]     led2_out;

wire                host_i_step;
wire                host_i_dir;
wire                host_i_motor;
wire     [3: 0]     host_i_sel;
wire                host_i_write_gate;
wire                host_i_write_data;
wire                host_i_side1;
wire     [3: 0]     host_i_x68000_sel;
wire     [3: 0]     floppy_o_x68000_sel;
wire                host_i_x68000_eject;
wire                host_i_x68000_lock;
wire                host_i_x68000_ledblink;
wire                host_o_x68000_diskindrive;
wire                host_o_x68000_insertfault;
wire                host_o_x68000_int;
wire                host_o_trk00;
wire                host_o_data;
wire                host_o_wpt;
wire                host_o_index;
wire                host_o_pin02;
wire                host_o_pin34;
wire                host_i_pin02;
wire                host_o_pin03;
wire                host_i_pin04;

//
// Host interface CTRL
//

wire                floppy_o_step;
wire                floppy_o_dir;
wire                floppy_o_motor;
wire     [3: 0]     floppy_o_sel;
wire                floppy_o_write_gate;
wire                floppy_o_write_data;
wire                floppy_o_side1;
wire                floppy_i_trk00;
wire                floppy_i_data;
wire                floppy_i_wpt;
wire                floppy_i_index;
wire                floppy_i_pin02;
wire                floppy_i_pin34;
wire                floppy_o_pin02;
wire                floppy_i_pin03;
wire                floppy_o_pin04;

wire                floppy_o_x68000_ledblink;
wire                floppy_o_x68000_lock;
wire                floppy_o_x68000_eject;

wire                floppy_i_x68000_diskindrive;
wire                floppy_i_x68000_insertfault;
wire                floppy_i_x68000_int;

wire                buzzer;

wire                i2c_scl_o_e;
wire                i2c_scl_o;
wire                i2c_sda_o_e;
wire                i2c_sda_o;

wire                tris_io0_din;
wire                tris_io0_dout;
wire                tris_io0_oe;

wire                tris_io1_din;
wire                tris_io1_dout;
wire                tris_io1_oe;

wire                tris_io2_din;
wire                tris_io2_dout;
wire                tris_io2_oe;

wire                tris_io3_din;
wire                tris_io3_dout;
wire                tris_io3_oe;

wire                ext_io_din;
wire                ext_io_dout;

wire                external_int;

wire                pushbutton0;
wire                pushbutton1;
wire                pushbutton2;

wire                led1;
wire                led2;

ALT_IOBUF i2c_scl_iobuf (.i(1'b0), .oe(i2c_scl_o_e), .o(i2c_scl_o), .io(GPIO1[9]));
ALT_IOBUF i2c_sda_iobuf (.i(1'b0), .oe(i2c_sda_o_e), .o(i2c_sda_o), .io(GPIO1[11]));

// connection of internal logics
//assign LED[7: 3] = fpga_led_internal;
assign fpga_clk_50 = FPGA_CLK1_50;
assign stm_hw_events = {{15{1'b0}}, SW, fpga_led_internal, fpga_debounced_buttons};



//=======================================================
//  Structural coding
//=======================================================

assign GPIO0 = 36'bz;
assign GPIO1 = 36'bz;
assign GPIO_JP3 = 8'bz;

assign host_i_sel[0] = GPIO0[8]; // !----
assign host_i_sel[1] = GPIO0[12]; // !----
assign host_i_sel[2] = GPIO0[16]; // !----
assign host_i_sel[3] = GPIO0[6]; // !----

assign host_i_x68000_sel[0] = GPIO0[26]; // !----
assign host_i_x68000_sel[1] = GPIO0[24]; // !----
assign host_i_x68000_sel[2] = GPIO0[0]; // !----
assign host_i_x68000_sel[3] = GPIO0[4]; // !----

assign host_i_step = GPIO1[18];   // !----
assign host_i_dir = GPIO1[14]; // !----
assign host_i_motor = GPIO0[22]; // !----
assign host_i_write_gate = GPIO1[24]; // !----
assign host_i_write_data = GPIO1[22]; // !----
assign host_i_side1 = GPIO1[32]; // !----
assign host_i_x68000_eject = GPIO0[14]; // !----
assign host_i_x68000_lock = GPIO0[18]; // !----
assign host_i_x68000_ledblink = GPIO0[20]; // !----
assign host_i_pin02 = GPIO0[32]; // !----


assign host_i_pin04 = GPIO0[2]; // !----

assign GPIO1[13] = host_o_x68000_diskindrive; // !----
assign GPIO1[17] = host_o_x68000_insertfault; // !----
assign GPIO1[21] = host_o_x68000_int; // !----
assign GPIO1[27] = host_o_trk00; // !----
assign GPIO1[31] = host_o_data; // !----
assign GPIO1[29] = host_o_wpt; // !----
assign GPIO0[9] = host_o_index;  // !----
assign GPIO0[29] = host_o_pin02;  // !----
assign GPIO1[35] = host_o_pin34;  // !----
assign LED[1] = led1_out[0];
assign LED[2] = led2_out[0];
assign LED[3] = led1_out[1];
assign LED[4] = led2_out[1];
assign LED[5] = led1_out[2];
assign LED[6] = led2_out[2];

assign GPIO1[33] = floppy_o_side1;  // side1 ----!!!
assign GPIO1[25] = floppy_o_write_gate; // wg ----!!!
assign GPIO1[23] = floppy_o_write_data; // wd ----!!!
assign GPIO1[19] = floppy_o_step; // step  ----!!!
assign GPIO1[15] = floppy_o_dir; // dir ----!!!
assign GPIO0[21] = floppy_o_motor; // mot  ----!!!
assign GPIO0[1]  = floppy_o_sel[3]; // ds3  ----!!!
assign GPIO0[19] = floppy_o_sel[2]; // ds2  ----!!!
assign GPIO0[13] = floppy_o_sel[1]; // ds1  ----!!!
assign GPIO0[11] = floppy_o_sel[0]; // ds0  ----!!!

assign floppy_i_trk00 = GPIO1[26]; //  ----!!!
assign floppy_i_data = GPIO1[30]; //  ----!!!
assign floppy_i_wpt = GPIO1[28]; //  ----!!!
assign floppy_i_index = GPIO0[10]; // ----!!!
assign floppy_i_pin02 = GPIO0[34]; // ----!!!
assign floppy_i_pin03 = GPIO0[28]; // !----

assign floppy_i_pin34 = GPIO1[34]; //  ----!!!

assign floppy_i_x68000_diskindrive = GPIO1[12]; //  ----!!!
assign floppy_i_x68000_insertfault = GPIO1[16]; //  ----!!!
assign floppy_i_x68000_int = GPIO1[20]; //  ----!!!

assign ext_io_din = GPIO0[30]; //  ----!!!

assign GPIO1[10] = buzzer; // ----!!!

assign GPIO0[3]  = floppy_o_pin04; // floppy pin 4 out

assign GPIO0[25] = ext_io_dout; // EXT_IO out

assign GPIO0[33] = floppy_o_x68000_sel[0]; // X68000 sel 0 out (ctrl)
assign GPIO0[31] = floppy_o_x68000_sel[1]; // X68000 sel 1 out / pin 3 (floppy out)
assign GPIO0[27] = host_o_pin03; // X68000 sel 1 out / pin 3 (Host out)
assign GPIO0[5] = floppy_o_x68000_sel[2]; // X68000 sel 2 out (ctrl)
assign GPIO0[7] = floppy_o_x68000_sel[3]; // X68000 sel 3 out (ctrl)
assign GPIO0[23] = floppy_o_x68000_ledblink; // X68000 Led blink
assign GPIO0[17] = floppy_o_x68000_lock; // X68000 Lock
assign GPIO0[15] = floppy_o_x68000_eject; // X68000 eject

assign GPIO0[35] = floppy_o_pin02; // floppy pin 02


assign i2c_sda_in = GPIO1[11];

assign tris_io0_din = GPIO1[2];
assign GPIO_JP3[2] = tris_io0_dout;
assign GPIO_JP3[3] = tris_io0_oe;

assign tris_io1_din = GPIO1[4];
assign GPIO_JP3[0] = tris_io1_dout;
assign GPIO_JP3[1] = tris_io1_oe;

assign tris_io2_din = GPIO1[6];
assign GPIO_JP3[7] = tris_io2_dout;
assign GPIO_JP3[6] = tris_io2_oe;

assign tris_io3_din = GPIO1[8];
assign GPIO_JP3[5] = tris_io3_dout;
assign GPIO_JP3[4] = tris_io3_oe;

assign external_int = GPIO1[0];

assign pushbutton0 = GPIO1[1];
assign pushbutton1 = GPIO1[3];
assign pushbutton2 = GPIO1[5];

soc_system u0(
               //Clock&Reset
               .clk_clk(FPGA_CLK1_50),                                      //                            clk.clk
               .reset_reset_n(hps_fpga_reset_n),                            //                          reset.reset_n
               //HPS ddr3
               .memory_mem_a(HPS_DDR3_ADDR),                                //                         memory.mem_a
               .memory_mem_ba(HPS_DDR3_BA),                                 //                               .mem_ba
               .memory_mem_ck(HPS_DDR3_CK_P),                               //                               .mem_ck
               .memory_mem_ck_n(HPS_DDR3_CK_N),                             //                               .mem_ck_n
               .memory_mem_cke(HPS_DDR3_CKE),                               //                               .mem_cke
               .memory_mem_cs_n(HPS_DDR3_CS_N),                             //                               .mem_cs_n
               .memory_mem_ras_n(HPS_DDR3_RAS_N),                           //                               .mem_ras_n
               .memory_mem_cas_n(HPS_DDR3_CAS_N),                           //                               .mem_cas_n
               .memory_mem_we_n(HPS_DDR3_WE_N),                             //                               .mem_we_n
               .memory_mem_reset_n(HPS_DDR3_RESET_N),                       //                               .mem_reset_n
               .memory_mem_dq(HPS_DDR3_DQ),                                 //                               .mem_dq
               .memory_mem_dqs(HPS_DDR3_DQS_P),                             //                               .mem_dqs
               .memory_mem_dqs_n(HPS_DDR3_DQS_N),                           //                               .mem_dqs_n
               .memory_mem_odt(HPS_DDR3_ODT),                               //                               .mem_odt
               .memory_mem_dm(HPS_DDR3_DM),                                 //                               .mem_dm
               .memory_oct_rzqin(HPS_DDR3_RZQ),                             //                               .oct_rzqin
               //HPS ethernet
               .hps_0_hps_io_hps_io_emac1_inst_TX_CLK(HPS_ENET_GTX_CLK),    //                   hps_0_hps_io.hps_io_emac1_inst_TX_CLK
               .hps_0_hps_io_hps_io_emac1_inst_TXD0(HPS_ENET_TX_DATA[0]),   //                               .hps_io_emac1_inst_TXD0
               .hps_0_hps_io_hps_io_emac1_inst_TXD1(HPS_ENET_TX_DATA[1]),   //                               .hps_io_emac1_inst_TXD1
               .hps_0_hps_io_hps_io_emac1_inst_TXD2(HPS_ENET_TX_DATA[2]),   //                               .hps_io_emac1_inst_TXD2
               .hps_0_hps_io_hps_io_emac1_inst_TXD3(HPS_ENET_TX_DATA[3]),   //                               .hps_io_emac1_inst_TXD3
               .hps_0_hps_io_hps_io_emac1_inst_RXD0(HPS_ENET_RX_DATA[0]),   //                               .hps_io_emac1_inst_RXD0
               .hps_0_hps_io_hps_io_emac1_inst_MDIO(HPS_ENET_MDIO),         //                               .hps_io_emac1_inst_MDIO
               .hps_0_hps_io_hps_io_emac1_inst_MDC(HPS_ENET_MDC),           //                               .hps_io_emac1_inst_MDC
               .hps_0_hps_io_hps_io_emac1_inst_RX_CTL(HPS_ENET_RX_DV),      //                               .hps_io_emac1_inst_RX_CTL
               .hps_0_hps_io_hps_io_emac1_inst_TX_CTL(HPS_ENET_TX_EN),      //                               .hps_io_emac1_inst_TX_CTL
               .hps_0_hps_io_hps_io_emac1_inst_RX_CLK(HPS_ENET_RX_CLK),     //                               .hps_io_emac1_inst_RX_CLK
               .hps_0_hps_io_hps_io_emac1_inst_RXD1(HPS_ENET_RX_DATA[1]),   //                               .hps_io_emac1_inst_RXD1
               .hps_0_hps_io_hps_io_emac1_inst_RXD2(HPS_ENET_RX_DATA[2]),   //                               .hps_io_emac1_inst_RXD2
               .hps_0_hps_io_hps_io_emac1_inst_RXD3(HPS_ENET_RX_DATA[3]),   //                               .hps_io_emac1_inst_RXD3
               //HPS SD card
               .hps_0_hps_io_hps_io_sdio_inst_CMD(HPS_SD_CMD),              //                               .hps_io_sdio_inst_CMD
               .hps_0_hps_io_hps_io_sdio_inst_D0(HPS_SD_DATA[0]),           //                               .hps_io_sdio_inst_D0
               .hps_0_hps_io_hps_io_sdio_inst_D1(HPS_SD_DATA[1]),           //                               .hps_io_sdio_inst_D1
               .hps_0_hps_io_hps_io_sdio_inst_CLK(HPS_SD_CLK),              //                               .hps_io_sdio_inst_CLK
               .hps_0_hps_io_hps_io_sdio_inst_D2(HPS_SD_DATA[2]),           //                               .hps_io_sdio_inst_D2
               .hps_0_hps_io_hps_io_sdio_inst_D3(HPS_SD_DATA[3]),           //                               .hps_io_sdio_inst_D3
               //HPS USB
               .hps_0_hps_io_hps_io_usb1_inst_D0(HPS_USB_DATA[0]),          //                               .hps_io_usb1_inst_D0
               .hps_0_hps_io_hps_io_usb1_inst_D1(HPS_USB_DATA[1]),          //                               .hps_io_usb1_inst_D1
               .hps_0_hps_io_hps_io_usb1_inst_D2(HPS_USB_DATA[2]),          //                               .hps_io_usb1_inst_D2
               .hps_0_hps_io_hps_io_usb1_inst_D3(HPS_USB_DATA[3]),          //                               .hps_io_usb1_inst_D3
               .hps_0_hps_io_hps_io_usb1_inst_D4(HPS_USB_DATA[4]),          //                               .hps_io_usb1_inst_D4
               .hps_0_hps_io_hps_io_usb1_inst_D5(HPS_USB_DATA[5]),          //                               .hps_io_usb1_inst_D5
               .hps_0_hps_io_hps_io_usb1_inst_D6(HPS_USB_DATA[6]),          //                               .hps_io_usb1_inst_D6
               .hps_0_hps_io_hps_io_usb1_inst_D7(HPS_USB_DATA[7]),          //                               .hps_io_usb1_inst_D7
               .hps_0_hps_io_hps_io_usb1_inst_CLK(HPS_USB_CLKOUT),          //                               .hps_io_usb1_inst_CLK
               .hps_0_hps_io_hps_io_usb1_inst_STP(HPS_USB_STP),             //                               .hps_io_usb1_inst_STP
               .hps_0_hps_io_hps_io_usb1_inst_DIR(HPS_USB_DIR),             //                               .hps_io_usb1_inst_DIR
               .hps_0_hps_io_hps_io_usb1_inst_NXT(HPS_USB_NXT),             //                               .hps_io_usb1_inst_NXT
               //HPS SPI
               .hps_0_hps_io_hps_io_spim1_inst_CLK(HPS_SPIM_CLK),           //                               .hps_io_spim1_inst_CLK
               .hps_0_hps_io_hps_io_spim1_inst_MOSI(HPS_SPIM_MOSI),         //                               .hps_io_spim1_inst_MOSI
               .hps_0_hps_io_hps_io_spim1_inst_MISO(HPS_SPIM_MISO),         //                               .hps_io_spim1_inst_MISO
               .hps_0_hps_io_hps_io_spim1_inst_SS0(HPS_SPIM_SS),            //                               .hps_io_spim1_inst_SS0
               //HPS UART
               .hps_0_hps_io_hps_io_uart0_inst_RX(HPS_UART_RX),             //                               .hps_io_uart0_inst_RX
               .hps_0_hps_io_hps_io_uart0_inst_TX(HPS_UART_TX),             //                               .hps_io_uart0_inst_TX
               //HPS I2C1
               .hps_0_hps_io_hps_io_i2c0_inst_SDA(HPS_I2C0_SDAT),           //                               .hps_io_i2c0_inst_SDA
               .hps_0_hps_io_hps_io_i2c0_inst_SCL(HPS_I2C0_SCLK),           //                               .hps_io_i2c0_inst_SCL
               //HPS I2C2
               .hps_0_hps_io_hps_io_i2c1_inst_SDA(HPS_I2C1_SDAT),           //                               .hps_io_i2c1_inst_SDA
               .hps_0_hps_io_hps_io_i2c1_inst_SCL(HPS_I2C1_SCLK),           //                               .hps_io_i2c1_inst_SCL
               //GPIO
               .hps_0_hps_io_hps_io_gpio_inst_GPIO09(HPS_CONV_USB_N),       //                               .hps_io_gpio_inst_GPIO09
               .hps_0_hps_io_hps_io_gpio_inst_GPIO35(HPS_ENET_INT_N),       //                               .hps_io_gpio_inst_GPIO35
               .hps_0_hps_io_hps_io_gpio_inst_GPIO40(HPS_LTC_GPIO),         //                               .hps_io_gpio_inst_GPIO40
               .hps_0_hps_io_hps_io_gpio_inst_GPIO53(HPS_LED),              //                               .hps_io_gpio_inst_GPIO53
               .hps_0_hps_io_hps_io_gpio_inst_GPIO54(HPS_KEY),              //                               .hps_io_gpio_inst_GPIO54
               .hps_0_hps_io_hps_io_gpio_inst_GPIO61(HPS_GSENSOR_INT),      //                               .hps_io_gpio_inst_GPIO61
               //FPGA Partion
               .led_pio_external_connection_export(fpga_led_internal),      //    led_pio_external_connection.export
               .dipsw_pio_external_connection_export(SW),                   //  dipsw_pio_external_connection.export
               .button_pio_external_connection_export(fpga_debounced_buttons),
                                                                            // button_pio_external_connection.export
               .floppy_interface_0_conduit_end_coe_c1_led1_out(led1_out),
               .floppy_interface_0_conduit_end_coe_c1_led2_out(led2_out),

               .floppy_interface_0_conduit_end_coe_c1_led1(led1),
               .floppy_interface_0_conduit_end_coe_c1_led2(led2),

               .floppy_interface_0_conduit_end_coe_c1_buzzer(buzzer),

               .floppy_interface_0_conduit_end_coe_c1_pushbutton0(pushbutton0),
               .floppy_interface_0_conduit_end_coe_c1_pushbutton1(pushbutton1),
               .floppy_interface_0_conduit_end_coe_c1_pushbutton2(pushbutton2),

               .floppy_interface_0_conduit_end_coe_c1_host_o_pin02(host_o_pin02),
               .floppy_interface_0_conduit_end_coe_c1_host_i_pin02(host_i_pin02),
               .floppy_interface_0_conduit_end_coe_c1_host_i_pin04(host_i_pin04),
               .floppy_interface_0_conduit_end_coe_c1_host_o_index(host_o_index),
               .floppy_interface_0_conduit_end_coe_c1_host_i_sel(host_i_sel),
               .floppy_interface_0_conduit_end_coe_c1_host_i_motor(host_i_motor),
               .floppy_interface_0_conduit_end_coe_c1_host_i_dir(host_i_dir),
               .floppy_interface_0_conduit_end_coe_c1_host_i_step(host_i_step),
               .floppy_interface_0_conduit_end_coe_c1_host_i_write_data(host_i_write_data),
               .floppy_interface_0_conduit_end_coe_c1_host_i_write_gate(host_i_write_gate),
               .floppy_interface_0_conduit_end_coe_c1_host_o_trk00(host_o_trk00),
               .floppy_interface_0_conduit_end_coe_c1_host_o_wpt(host_o_wpt),
               .floppy_interface_0_conduit_end_coe_c1_host_o_data(host_o_data),
               .floppy_interface_0_conduit_end_coe_c1_host_i_side1(host_i_side1),
               .floppy_interface_0_conduit_end_coe_c1_host_o_pin34(host_o_pin34),
               .floppy_interface_0_conduit_end_coe_c1_host_i_x68000_sel(host_i_x68000_sel),
               .floppy_interface_0_conduit_end_coe_c1_host_o_pin03(host_o_pin03),
               .floppy_interface_0_conduit_end_coe_c1_host_i_x68000_eject(host_i_x68000_eject),
               .floppy_interface_0_conduit_end_coe_c1_host_i_x68000_lock(host_i_x68000_lock),
               .floppy_interface_0_conduit_end_coe_c1_host_i_x68000_ledblink(host_i_x68000_ledblink),
               .floppy_interface_0_conduit_end_coe_c1_host_o_x68000_diskindrive(host_o_x68000_diskindrive),
               .floppy_interface_0_conduit_end_coe_c1_host_o_x68000_insertfault(host_o_x68000_insertfault),
               .floppy_interface_0_conduit_end_coe_c1_host_o_x68000_int(host_o_x68000_int),

               .floppy_interface_0_conduit_end_coe_c1_floppy_i_pin02(floppy_i_pin02),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_pin02(floppy_o_pin02),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_pin04(floppy_o_pin04),
               .floppy_interface_0_conduit_end_coe_c1_floppy_i_index(floppy_i_index),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_sel(floppy_o_sel),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_motor(floppy_o_motor),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_dir(floppy_o_dir),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_step(floppy_o_step),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_write_data(floppy_o_write_data),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_write_gate(floppy_o_write_gate),
               .floppy_interface_0_conduit_end_coe_c1_floppy_i_trk00(floppy_i_trk00),
               .floppy_interface_0_conduit_end_coe_c1_floppy_i_wpt(floppy_i_wpt),
               .floppy_interface_0_conduit_end_coe_c1_floppy_i_data(floppy_i_data),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_side1(floppy_o_side1),
               .floppy_interface_0_conduit_end_coe_c1_floppy_i_pin34(floppy_i_pin34),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_x68000_sel(floppy_o_x68000_sel),
               .floppy_interface_0_conduit_end_coe_c1_floppy_i_pin03(floppy_i_pin03),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_x68000_eject(floppy_o_x68000_eject),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_x68000_lock(floppy_o_x68000_lock),
               .floppy_interface_0_conduit_end_coe_c1_floppy_o_x68000_ledblink(floppy_o_x68000_ledblink),
               .floppy_interface_0_conduit_end_coe_c1_floppy_i_x68000_diskindrive(floppy_i_x68000_diskindrive),
               .floppy_interface_0_conduit_end_coe_c1_floppy_i_x68000_insertfault(floppy_i_x68000_insertfault),
               .floppy_interface_0_conduit_end_coe_c1_floppy_i_x68000_int(floppy_i_x68000_int),

               .floppy_interface_0_conduit_end_coe_c1_tris_io0_dout(tris_io0_dout),
               .floppy_interface_0_conduit_end_coe_c1_tris_io0_din(tris_io0_din),
               .floppy_interface_0_conduit_end_coe_c1_tris_io0_oe(tris_io0_oe),

               .floppy_interface_0_conduit_end_coe_c1_tris_io1_dout(tris_io1_dout),
               .floppy_interface_0_conduit_end_coe_c1_tris_io1_din(tris_io1_din),
               .floppy_interface_0_conduit_end_coe_c1_tris_io1_oe(tris_io1_oe),

               .floppy_interface_0_conduit_end_coe_c1_tris_io2_dout(tris_io2_dout),
               .floppy_interface_0_conduit_end_coe_c1_tris_io2_din(tris_io2_din),
               .floppy_interface_0_conduit_end_coe_c1_tris_io2_oe(tris_io2_oe),

               .floppy_interface_0_conduit_end_coe_c1_tris_io3_dout(tris_io3_dout),
               .floppy_interface_0_conduit_end_coe_c1_tris_io3_din(tris_io3_din),
               .floppy_interface_0_conduit_end_coe_c1_tris_io3_oe(tris_io3_oe),

               .floppy_interface_0_conduit_end_coe_c1_ext_io_dout(ext_io_dout),
               .floppy_interface_0_conduit_end_coe_c1_ext_io_din(ext_io_din),

               .floppy_interface_0_conduit_end_coe_c1_external_int(external_int),

               .hps_0_i2c2_out_data(i2c_sda_o_e),
               .hps_0_i2c2_sda(i2c_sda_o),
               .hps_0_i2c2_clk_clk(i2c_scl_o_e),
               .hps_0_i2c2_scl_in_clk(i2c_scl_o),

               .hps_0_h2f_reset_reset_n(hps_fpga_reset_n),                  //                hps_0_h2f_reset.reset_n
               .hps_0_f2h_cold_reset_req_reset_n(~hps_cold_reset),          //       hps_0_f2h_cold_reset_req.reset_n
               .hps_0_f2h_debug_reset_req_reset_n(~hps_debug_reset),        //      hps_0_f2h_debug_reset_req.reset_n
               .hps_0_f2h_stm_hw_events_stm_hwevents(stm_hw_events),        //        hps_0_f2h_stm_hw_events.stm_hwevents
               .hps_0_f2h_warm_reset_req_reset_n(~hps_warm_reset),          //       hps_0_f2h_warm_reset_req.reset_n

           );

// Debounce logic to clean out glitches within 1ms
debounce debounce_inst(
             .clk(fpga_clk_50),
             .reset_n(hps_fpga_reset_n),
             .data_in(KEY),
             .data_out(fpga_debounced_buttons)
         );
defparam debounce_inst.WIDTH = 2;
defparam debounce_inst.POLARITY = "LOW";
defparam debounce_inst.TIMEOUT = 50000;               // at 50Mhz this is a debounce time of 1ms
defparam debounce_inst.TIMEOUT_WIDTH = 16;            // ceil(log2(TIMEOUT))

// Source/Probe megawizard instance
hps_reset hps_reset_inst(
              .source_clk(fpga_clk_50),
              .source(hps_reset_req)
          );

altera_edge_detector pulse_cold_reset(
                         .clk(fpga_clk_50),
                         .rst_n(hps_fpga_reset_n),
                         .signal_in(hps_reset_req[0]),
                         .pulse_out(hps_cold_reset)
                     );
defparam pulse_cold_reset.PULSE_EXT = 6;
defparam pulse_cold_reset.EDGE_TYPE = 1;
defparam pulse_cold_reset.IGNORE_RST_WHILE_BUSY = 1;

altera_edge_detector pulse_warm_reset(
                         .clk(fpga_clk_50),
                         .rst_n(hps_fpga_reset_n),
                         .signal_in(hps_reset_req[1]),
                         .pulse_out(hps_warm_reset)
                     );
defparam pulse_warm_reset.PULSE_EXT = 2;
defparam pulse_warm_reset.EDGE_TYPE = 1;
defparam pulse_warm_reset.IGNORE_RST_WHILE_BUSY = 1;

altera_edge_detector pulse_debug_reset(
                         .clk(fpga_clk_50),
                         .rst_n(hps_fpga_reset_n),
                         .signal_in(hps_reset_req[2]),
                         .pulse_out(hps_debug_reset)
                     );
defparam pulse_debug_reset.PULSE_EXT = 32;
defparam pulse_debug_reset.EDGE_TYPE = 1;
defparam pulse_debug_reset.IGNORE_RST_WHILE_BUSY = 1;

reg [25: 0] counter;
reg led_level;
always @(posedge fpga_clk_50 or negedge hps_fpga_reset_n) begin
    if (~hps_fpga_reset_n) begin
        counter <= 0;
        led_level <= 0;
    end

    else if (counter == 24999999) begin
        counter <= 0;
        led_level <= ~led_level;
    end
    else
        counter <= counter + 1'b1;
end

assign LED[0] = led_level;

reg [25: 0] counter_leds;
reg leds_state;
always @(posedge fpga_clk_50 or negedge hps_fpga_reset_n) begin
    if (~hps_fpga_reset_n)
		begin
			counter_leds <= 0;
			leds_state <= 1'bz; // Led
		end

    else if (counter_leds < 250000)
		begin
			if (led1 == 1)
				leds_state <= 0; // Led
			else
				leds_state <= 1'bz; // Led

			counter_leds <= counter_leds + 1'b1;
		end
    else if (counter_leds < (250000*2))
		begin
			if (led2 == 1)
				leds_state <= 1; // Led
			else
				leds_state <= 1'bz; // Led

			counter_leds <= counter_leds + 1'b1;
		end
    else
		counter_leds <= 0;
end
assign GPIO1[7] = leds_state;

endmodule
