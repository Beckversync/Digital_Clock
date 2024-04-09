`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/24/2023 08:14:59 PM
// Design Name: 
// Module Name: SevenSegment
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

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/24/2023 08:57:47 PM
// Design Name: 
// Module Name: DigitalClock_12hrs
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


module DigitalClock_12hrs(
    input clk,
    input btn0_clock, // selecting and deselecting clock mode
    input btn1_up, // to increase hours or minutes
    input btn2_down, // to decrease hours or minutes
    input btn3_toggle, // to toggle between minutes and hours
    output [3:0] seg0,
    output [3:0] seg1,
    output [3:0] seg2,
    output [3:0] seg3, // 7_segment display
    output [3:0] an, // to enable 4 7_segment displays
    output AM_PM_indicator_led, // light on indicates PM, light off indicates AM
    output clock_mode_indicator_led,// indicates clock mode when light on 
    output [5:0] sec_led
    );
    
    reg [31:0] counter = 0;
    parameter max_count = 125_000_000;
    
    reg [5:0] hours, min, sec = 0;// t?i này ch?y t?i 60
    reg [3:0]  min_ones, min_tens, hours_ones, hours_tens = 0;
    reg toggle = 0;
    
    reg pm = 0;
    assign AM_PM_indicator_led = pm; // sáng ?èn thì ?ang là pm, t?i ?èn thì ?ang là am
    reg clock_mode = 0;
    assign clock_mode_indicator_led = clock_mode; // sáng ?èn thì clock on, t?i ?èn thì clock off
    
    SevenSegment SSM(.clk(clk), .min_ones(min_ones), .min_tens(min_tens), .hours_ones(hours_ones), .hours_tens(hours_tens), .seg0(seg0), .seg1(seg1), .seg2(seg2), .seg3(seg3), .an(an));
    
    parameter display_time = 1'b0;
    parameter set_time = 1'b1;
    reg current_mode = set_time;
    
    assign sec_led[0] = sec[0];
    assign sec_led[1] = sec[1];
    assign sec_led[2] = sec[2];
    assign sec_led[3] = sec[3];
    assign sec_led[4] = sec[4];
    assign sec_led[5] = sec[5];
    
    always @(posedge clk)
    begin 
        case(current_mode)
            display_time:
            begin
                if(btn0_clock)
                begin
                    clock_mode <= 0;
                    current_mode <= set_time;
                    counter <= 0;
                    toggle <= 0;
                    sec <= 0;
                end
                
                if (counter < max_count)
                begin
                    counter <= counter + 1;  
                end
                else
                begin
                    counter <= 0;
                    sec <= sec + 1;
                end
            end // end display_time
            
            set_time:
            begin
                if (btn0_clock)
                begin
                    clock_mode <= 1;
                    current_mode <= display_time;
                end
                
                if(counter < 31_250_000)
                begin
                    counter <= counter + 1;
                end
                else
                begin
                    counter <= 0;   
                    case (toggle)
                        1'b0: 
                        begin
                            if (btn1_up)
                            begin
                                min <= min + 1;
                            end
                            
                            if (btn2_down)
                            begin
                                if (min > 0)
                                begin
                                    min <= min - 1;
                                end
                                
                                else if (hours > 1)
                                begin
                                    hours <= hours - 1;
                                    min <= 59;
                                end
                                
                                else if (hours == 1)
                                begin
                                    hours <= 12;
                                    min <= 59;
                                end
                            end
                            
                            if(btn3_toggle)
                            begin
                                toggle <= 1;
                            end
                        end // end toggle == 0;
                        
                        1'b1: 
                        begin
                            if (btn1_up)
                            begin
                                hours <= hours + 1;
                            end 
                            
                            if (btn2_down)
                            begin
                                if (hours > 1)
                                begin
                                    hours <= hours - 1;
                                end
                                
                                else if (hours == 1)
                                begin
                                    hours <= 12;
                                end
                                
                                if (btn3_toggle)
                                begin
                                    toggle <= 0;
                                end
                            end
                        end // end toggle == 1;    
                    endcase // endcase toggle
                end
            end // end set_clock
         endcase // end case current_mode
         
// digital clock 12hrs format

        if (sec >= 60)
        begin
            sec <= 0;
            min <= min + 1;
        end         
        
        if (min >= 60)
        begin
            min <= 0;
            hours <= hours + 1;
        end
        
        if (hours >= 24)
        begin
            hours <= 0;
        end
        
// AM_PM time 
        else // 0 = AM_FM time
        begin
            min_ones <= min % 10;
            min_tens <= min / 10;
            if (hours < 12) // luc còn if
            begin
                if(hours == 0) // 12h sang
                begin
                    hours_ones <= 2;
                    hours_tens <= 1;
                end
                else
                begin
                    hours_ones = hours % 10;
                    hours_tens = hours / 10;
                end
                pm <= 0;
            end
            
            else // sang chieu roi
            begin
                if (hours == 12)
                begin
                    hours_ones <= 2;
                    hours_tens <= 1;
                end
                else
                begin
                    hours_ones <= (hours - 12) % 10;
                    hours_tens <= (hours - 12) / 10;
                end
                pm <= 1;
            end // end pm
        end // end clock displays
        
    end
endmodule

module SevenSegment(
    input clk,
    input [3:0] min_ones,
    input [3:0] min_tens,
    input [3:0] hours_ones,
    input [3:0] hours_tens,
    output reg [3:0] seg0,
    output reg [3:0] seg1,
    output reg [3:0] seg2,
    output reg [3:0] seg3,
    output reg [3:0] an
    );
    
    reg [1:0] digit_display = 0;
    reg [3:0] display [3:0];
    
    reg [26:0] counter = 0;
    parameter max_count = 625_000;
    wire [3:0] four_bit [3:0];
    
    assign four_bit[0] = min_ones;
    assign four_bit[1] = min_tens;
    assign four_bit[2] = hours_ones;
    assign four_bit[3] = hours_tens;
    
    always @(posedge clk)
    begin
        if(counter < max_count)
        begin
            counter <= counter + 1;
        end
        else
        begin
            digit_display <= digit_display + 1;
            counter <= 0;   
        end
    
        case(four_bit[digit_display])
            4'b0000 : display[digit_display] <= 4'b0000; // 0
            4'b0001 : display[digit_display] <= 4'b0001; // 1
            4'b0010 : display[digit_display] <= 4'b0010; // 2
            4'b0011 : display[digit_display] <= 4'b0011; // 3
            4'b0100 : display[digit_display] <= 4'b0100; // 4
            4'b0101 : display[digit_display] <= 4'b0101; // 5
            4'b0110 : display[digit_display] <= 4'b0110; // 6
            4'b0111 : display[digit_display] <= 4'b0111; // 7
            4'b1000 : display[digit_display] <= 4'b1000; // 8
            4'b1001 : display[digit_display] <= 4'b1001; // 9
            default: display[digit_display] <= 4'b1111; // F if wrong
        endcase
        
        case(digit_display)
            0: begin
                an <= 4'b1110;
                seg0 <= display[0];
            end
            
            1: begin
                an <= 4'b1101;
                seg1 <= display[1];
            end
            
            2: begin
                an <= 4'b1011;
                seg2 <= display[2];
            end
            
            3: begin
                an <= 4'b0111;
                seg3 <= display[3];
            end
         endcase       
    end
endmodule