`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/01 23:03:31
// Design Name: 
// Module Name: FP16_mux
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


module FP16_mcl(
    input data1,
    input data2,
    input rst,
    input input_valid,
    input clk,
    output datanew,
    output output_update
    );
    
    wire clk;
    wire [15:0] data1;
    wire [15:0] data2; 
    wire rst;
    wire input_valid;
    reg [15:0] datanew;
    reg output_update;
    
    reg sign_1;          //for step1:check
    reg sign_2;
    reg [6:0]exp1;
    reg [6:0]exp2;
    reg [11:0]rm1;
    reg [11:0]rm2;
    reg overflow1;
    reg check_over;
    reg cal_over;       //for step2:calculate
    reg overflow2;
    reg [21:0]rmcache;
    reg [6:0]expcache;
    reg sign;
    reg carry1_over;    //for step3:carry
    reg overflow3;
    reg [21:0]rmcache2;
    reg [6:0]expcache2;
    reg sign2;
    reg round_over;      //for step4:round to nearest even
    reg overflow4;
    reg sign3;
    reg [6:0]expcache3;
    reg [11:0]rmcache3;
    reg carry2_over;    //for step5:carry again
    reg overflow5;
    reg [11:0]rmcache4;
    reg [6:0]expcache4;
    reg sign4;    
    
    //step1: check 
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            sign_1 <= 1'b0;
            sign_2 <= 1'b0;
            exp1 <= 7'd0;
            exp2 <= 7'd0;
            rm1 <= 12'd0;
            rm2 <= 12'd0;
            overflow1 = 1'b0;
            check_over <= 1'b0;
        end
        else if(input_valid)    begin
            check_over <= 1'b1;
            sign_1 <= data1[15];
            sign_2 <= data2[15];
            exp1 <= {2'b00,data1[14:10]};
            exp2 <= {2'b00,data2[14:10]};
            if((&data1[14:10]) || (&data2[14:10]))  begin   //overflow
                overflow1 <= 1'b1;
                rm1 <= rm1;
                rm2 <= rm2;
            end
            else if((~(|data1[14:0])) || (~(|data2[14:0]))) begin   //0
                overflow1 <= 1'b0;
                rm1 <= 12'd0;
                rm2 <= rm2;
            end
            else    begin
                overflow1 <= 1'b0;
                rm1 <= {2'b01,data1[9:0]};
                rm2 <= {2'b01,data2[9:0]};
            end
        end
        else begin
            sign_1 <= sign_1;
            sign_2 <= sign_2;
            exp1 <= exp1;
            exp2 <= exp2;
            rm1 <= rm1;
            rm2 <= rm2;
            overflow1 <= overflow1;
            check_over <= 1'b0;
        end
    end
    
    //step2:calculate
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            cal_over <= 1'b0;
            overflow2 <= 1'b0;
            rmcache <= 22'd0;
            expcache <= 7'd0;
            sign <= 1'b0;
        end
        else if(check_over) begin
            cal_over <= 1'b1;
            overflow2 <= overflow1;
            sign <= sign_1 ^ sign_2;
            if(overflow1)   begin
                rmcache <= rmcache;
                expcache <= expcache;
            end
            else    begin
                rmcache <= rm1 * rm2;
                expcache <= exp1 + exp2 - 7'd15;
            end
        end
        else    begin
            cal_over <= 1'b0;
            overflow2 <= overflow2;
            rmcache <= rmcache;
            expcache <= expcache;
            sign <= sign;
        end
    end
    
    //step3:carry
    always @(posedge clk or posedge rst)    begin
        if(rst) begin
            carry1_over <= 1'b0;
            overflow3 <= 1'b0;
            sign2 <= 1'b0;
            expcache2 <= 7'd0;
            rmcache2 <= 22'd0;
        end
        else if(cal_over)   begin
            carry1_over <=1'b1;
            sign2 <= sign;
            if(overflow2)   begin
                overflow3 <= overflow2;
                rmcache2 <= rmcache2;
                expcache2 <= expcache2;
            end
            else    begin
                if(rmcache[21]) begin
                    rmcache2 <= rmcache >> 1;
                    if(expcache == 7'd30)   begin
                        overflow3 <= 1'b1;
                        expcache2 <= expcache2;
                    end   
                    else begin
                        overflow3 <= overflow2 ;
                        expcache2 <= expcache + 7'd1;
                    end
                end
                else    begin
                    rmcache2 <= rmcache;
                    expcache2 <= expcache;
                    overflow3 <= overflow2;
                end
            end
        end
        else    begin
            carry1_over <= 1'b0;
            overflow3 <= overflow2;
            rmcache2 <= rmcache2;
            sign2 <= sign2;
            expcache2 <= expcache2;
        end
    end
    
    //step4:round to nearest even
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            round_over <= 1'b0;
            overflow4 <= 1'b0;
            sign3 <= 1'b0;
            expcache3 <= 7'd0;
            rmcache3 <= 12'd0;
        end
        else if(carry1_over)    begin
            round_over <= 1'b1;
            overflow4 <= overflow3;
            sign3 <= sign2;
            if(overflow3)   begin
                expcache3 <= expcache3;
                rmcache3 <= rmcache3;
            end
            else    begin
                expcache3 <= expcache2;
                if(rmcache2[9] && (rmcache2[10] || (|rmcache2[8:0])))
                    rmcache3 <= rmcache2[21:10] + 12'd1;
                else
                    rmcache3 <= rmcache2[21:10];
            end
        end
        else    begin
            round_over <= 1'b0;
            overflow4 <= overflow4;
            sign3 <= sign3;
            expcache3 <= expcache3;
            rmcache3 <= rmcache3;
        end
    end
    
    //step5:carry again
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            carry2_over <= 1'b0;
            overflow5 <= 1'b0;
            sign4 <= 1'b0;
            expcache4 <= 7'd0;
            rmcache4 <= 12'd0;
        end
        else if(round_over)   begin
            carry2_over <=1'b1;
            sign4 <= sign3;
            if(overflow4)   begin
                overflow5 <= overflow4;
                rmcache4 <= rmcache4;
                expcache4 <= expcache4;
            end
            else    begin
                if(rmcache3[11]) begin
                    rmcache4 <= rmcache3 >> 1;
                    if(expcache3 >= 7'd30)  begin
                        overflow5 <= 1'b1;
                        expcache4 <= expcache4;
                    end
                    else begin
                        overflow5 <= overflow4;
                        expcache4 <= expcache3 + 7'd1;
                    end
                end
                else    begin
                    rmcache4 <= rmcache3;
                    expcache4 <= expcache3;
                    overflow5 <= overflow4;
                end
            end
        end
        else    begin
            carry2_over <= 1'b0;
            overflow5 <= overflow5;
            rmcache4 <= rmcache4;
            sign4 <= sign4;
            expcache4 <= expcache4;
        end
    end
    
    //step5:result;
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            datanew <= 16'd0;
            output_update <= 1'b0;
        end
        else if(carry2_over)    begin
            if(((expcache4 > 7'd30) && ~expcache4[6]) || overflow5)
                datanew <= {sign4,15'h7fff};
            else if(expcache4[6] || ~(|expcache4))
                datanew <= 16'h0000;
            else
                datanew <= {sign4,expcache4[4:0],rmcache4[9:0]};
        end
        else begin
            datanew <= datanew;
            output_update <= 1'b0;
        end
    end

endmodule
