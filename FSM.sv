`timescale 1ns / 1ps
//////////////////////////Design code///////////////////////////
 
module top(input clk,rst,din,output reg dout);
  
  enum bit [2:0]
  {
   idle = 3'b001,
    s0 = 3'b010,
    s1 = 3'b100
  }state,next_state;
  
  ///reset logic
  always@(posedge clk)
    begin
      if(rst == 1'b1)
         state <= idle;
      else 
         state <= next_state;
    end
  
  ///decoding next state and output logic
  always@(state,din)
    begin
      case(state)
        idle: begin
            dout = 1'b0;
          if(rst == 1'b1)
            next_state = idle;
          else
            next_state = s0;
        end
        
        s0: begin
          if(din == 1'b1)begin
            next_state = s1;
            dout = 0;
          end
          else begin  
            next_state = s0;
            dout = 0;
          end
        end
          
         s1:begin
          if(din == 1'b1)begin
            next_state = s0;
            dout = 1'b1;
          end
          else begin  
            next_state = s1;
            dout = 0;
          end  
        end
          
        default:
          begin  
            next_state = idle;
            dout = 0;
          end 
        
      endcase
    end
 
       
endmodule
 


module FSM();
reg clk = 0;
  reg  din = 0;
  reg rst = 0;
  wire dout;
  reg temp = 0;
  
   initial begin
   #2;
   temp = 1;
   #10;
   temp = 0;
  end  
 
  top dut (clk,rst,din,dout);
  
  always #5 clk = ~clk;
  
  initial begin
    rst = 1;
    #30;
    rst = 0;
    din = 1;
    #45;
    din = 0;
    #25;
    rst = 1;
    #40;
    rst = 0;
  end
 //////////staes are one hot encoding whie the rst is active low////////// 
 //A1: assert property(@(posedge clk) !rst |-> $onehot(top.state));
 //A2:assert property(@(posedge clk) !rst |-> $countones(top.state)==1);
 
 
 // behaviour of the state when rst is asserted///
// A3:assert property(@(posedge clk) $rose(rst) |-> (top.state==top.idle))$info("suc at %0t",$time);else $error("Failed at %0t ",$time);
 // rst asserted behviour of the  state as long as the rst asserted
 //A4:assert property (@(posedge clk) $rose(rst) |=>  ((top.state == top.idle)[*1:18]) within (rst[*1:18] ##1 !rst)) $info("Suc at %0t",$time);
 
 
 /////////////////    (3) state transition when rst is low and din is high/low
 sequence s0;
 (top.state==top.idle)##1 (top.state==top.s0);
 endsequence
 
 sequence s2;
(top.state == top.s0) ##1 (top.state == top.s1);
endsequence
 
 
sequence s3;
(top.state == top.s1) ##1 (top.state == top.s0);
endsequence 
//////////////////////////////////
sequence s4;
(top.state == top.idle) ##1 (top.state == top.idle);
endsequence
 
 
sequence s5;
(top.state == top.s0) ##1 (top.state == top.s0);
endsequence
 
 
sequence s6;
(top.state == top.s1) ##1 (top.state == top.s1);
endsequence


//A5: assert property(@(posedge clk) disable iff(rst) din |-> (s0 or s2 or s3))$info("success at %0t",$time);else $error("success at %0t",$time);// when din high
//// when din is low
//A6:assert property(@(posedge clk) disable iff(rst) din |-> (s4 or s5 or s6))$info("success at %0t",$time);else $error("success at %0t",$time);

///////        (4) all states are covered
 
//A7:assert property (@(posedge clk) $rose(temp) |-> (##[0:18] (top.state == top.idle) ##[1:18] (top.state == top.s0) ##[1:18] (top.state == top.s1) ))$info("Suc at %0t",$time);
 
 
//////           (5) checking output behavior
 
 
A8:assert property (@(posedge clk) disable iff(rst) ((top.state == top.s1) && ($past(top.state) == top.s0)) |-> (dout == 1'b1))$info("Suc at %0t",$time);
  initial begin
    #180;
    $finish;    
  end
endmodule
