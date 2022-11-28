`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/02 18:47:24
// Design Name: 
// Module Name: FP16_mux_tb
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


module FP16_mcl_tb(

    );
    reg clk;
    reg [15:0]data_in1;
    reg [15:0]data_in2;
    reg rst;
    reg input_valid;
    wire [15:0]data_out;
    wire output_update;
    
    always #5 clk = ~clk;
    
    initial begin
        rst = 1;
        clk = 1;
        input_valid = 1;      
        /*  254 * 7.6836 = 1951.6344 , cal:1952(0x67a0) , pass  */
        data_in1 = 16'h5bf0;  //254
        data_in2 = 16'h47af;  //7.6836
        
        #20 rst = 0;
        #10       
        /*  4.25 * 6.375 = 27.09375 , cal:27.09375(0x4ec6) , pass   */
        data_in1 = 16'h4440;    //4.25
        data_in2 = 16'h4660;    //6.375
        #5
        input_valid = 0;
        #60 rst = 1;
               
    end
    
    FP16_mcl U1 (
    .data1(data_in1),
    .data2(data_in2),
    .clk(clk),
    .rst(rst),
    .input_valid(input_valid),
    .datanew(data_out),
    .output_update(output_update)
    );
    
endmodule
