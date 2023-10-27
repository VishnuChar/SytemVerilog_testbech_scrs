`timescale 1ns / 1ps
module FIFO_Top(input clk, rst, wr, rd,
input [7:0]din,
output reg[7:0] dout,
output reg empty, full

);
reg [3:0] wptr=0,rdptr=0;// pointers enable the  t read and write the quea
reg [7:0] mem [15:0];// bredth of the fifo 16 like quaue
reg [3:0] cnt;// enables the number of counts to ensure the fullfilment of the fifo
always@(posedge clk)
begin
if(rst==1'b1)
begin
cnt<=0;
wptr<=0;
rdptr<=0;
end
else if (wr && !full)
begin
if(cnt<15)
begin
mem[wptr]<= din;
wptr<=wptr+1;
cnt<=cnt+1;
end
end
else if( rd && !empty)
begin
if(cnt>0)
begin
dout<=mem[rdptr];
rdptr<=rdptr+1;
cnt<=cnt-1;
end
end
 if (wptr==15)
wptr<=0;
 if(rdptr==15)
 rdptr<=0;
end
assign full  =(cnt==15)?1'b1:1'b0;
assign empty =(cnt==0)?1'b1:1'b0;
endmodule

module FIF0_Assertions();
reg clk=0, rst=0, wr=0, rd=0;
reg [7:0] din =0;
wire [7:0] dout; 
wire empty, full;
integer i=0;
reg start=0;
FIFO_Top dut (.clk(clk),. rst(rst), .wr(wr), .rd(rd),.din(din),.dout(dout),.empty(empty),.full(full));
always #5 clk=~clk;
initial begin
#2;
start=1;
#10;
start=0;
end
reg temp=0;
initial begin
#292;
temp=1;
#10;
temp=0;
end
// Assertions check for empty and full check if rst is high 
//A1: assert property (@(posedge clk)$rose(rst)|->(empty && !full) )$info("succ at %0t",$time);else $error ("Failed at %0t",$time);
// At level of the signal
//A2: assert property (@(posedge clk) rst|->(empty && !full) )$info("succ at %0t",$time);else $error ("Failed at %0t",$time);
// For the entire duration
//A3: assert property (@(posedge clk)$rose(rst)|->(empty && !full)[*1:31 ] ##1(!rst|| temp) )$info("succ at %0t",$time);else $error ("Failed at %0t",$time);
// Generating the Stimulus for The module
//initial begin
//$display(".............STARTING TEST............");
//$display(".............EMPTY && FULL CHECK........");
//@(posedge clk) {rst,wr,rd}=3'b100;
//@(posedge clk) {rst,wr,rd}=3'b100;
//@(posedge clk) {rst,wr,rd}=3'b101;
//@(posedge clk) {rst,wr,rd}=3'b111;
//end
// Reading an empty FIFO
//A4:assert property(@(posedge clk) disable iff(rst) empty |-> !rd  )$info("succ at %0t",$time);
//// Stimulus generation
//initial begin
//$display(".............STARTING TEST............");
//$display(".............READING AN EMPTY FIFO........");
//@(posedge clk) {rst,wr,rd}=3'b100;
//@(posedge clk) {rst,wr,rd}=3'b001;
//@(posedge clk) {rst,wr,rd}=3'b000;
//@(posedge clk);
//end
// writing into the fifo
// Stimulus generation
//A5:assert property(@(posedge clk) disable iff(rst)   full |-> !wr  )$info("succ at %0t",$time);
//initial begin
//$display(".............STARTING TEST............");
//$display(".............WRITING INTO FULL FIFO........");
//@(posedge clk) {rst,wr,rd}=3'b100;
//#40;
//@(posedge clk) {rst,wr,rd}=3'b010;
//for(i=0;i<16;i++)
//din<=$urandom();
//@(posedge clk);
//write();
//@(posedge clk) {rst,wr,rd}=3'b010;
//@(posedge clk) {rst,wr,rd}=3'b000;
//@(posedge clk);
//end
//A6:assert property(@(posedge clk) disable iff(rst)  empty |-> !rd  )$info("succ at %0t",$time);
initial begin
$display(".............STARTING TEST............");
$display(".............READING FROM FULL FIFO........");
@(posedge clk) {rst,wr,rd}=3'b100;
#40;
// writin into the fifo
@(posedge clk) {rst,wr,rd}=3'b010;
for(i=0;i<15;i++)
{rst,wr,rd}=3'b010;
din<=$urandom();

@(posedge clk);
#10;
//read pointer is incrementing by 1
//A7:assert property (@(posedge clk) $rose(wr) |=>(top.wptr==$past(top.wptr+1)) )$info("succ at %0t",$time);
//reading from fifo
@(posedge clk) {rst,wr,rd}=3'b010;
for(i=0;i<15;i++)
{rst,wr,rd}=3'b001;
@(posedge clk);
#14;

end
//checking for the dout to large
always @(posedge  clk)
begin
assert(!$isunknown(dout))info("succ at %0t",$time);else $error("Failed at %0t",$time);
end
initial begin
#400;
$finish();
end
endmodule
