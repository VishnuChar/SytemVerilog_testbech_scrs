`timescale 1ns / 1ps
module andt (
input clk, rst, up, load,
input [7:0] loadin,
output reg [7:0] y
);
 
always@(posedge clk)
begin
if(rst == 1'b1)
y <= 8'b00000000;
else if (load == 1'b1)
y <= loadin;
else begin
if(up == 1'b1)
 y <= y + 1;
 else
 y <= y - 1;
 end
end
endmodule
 
class transaction;
randc bit [7:0] loadin;
bit [7:0] y;
endclass
 
class generator;
transaction t;
mailbox mbx;
event done;
integer i;
 
function new(mailbox mbx);
this.mbx = mbx;
endfunction
 
task run();
t = new();
for(i=0;i<10;i++)begin
t.randomize();
mbx.put(t);
$display("[GEN]: Data send to driver");
@(done);
end
endtask
endclass
 
interface andt_intf();
logic clk,rst, up, load;
logic [7:0] loadin;
logic [7:0] y;
endinterface
 
class driver;
mailbox mbx;
transaction t;
event done;
 
virtual andt_intf vif;
 
function new(mailbox mbx);
this.mbx = mbx;
endfunction
 
 
task run();
t= new();
forever begin
mbx.get(t);
vif.loadin = t.loadin;
$display("[DRV] : Trigger Interface");
->done; 
@(posedge vif.clk);
end
endtask
 
 
endclass
 
class monitor;
virtual andt_intf vif;
mailbox mbx;
transaction t;
 
function new(mailbox mbx);
this.mbx = mbx;
endfunction
 
task run();
t = new();
forever begin
t.loadin = vif.loadin;
t.y = vif.y;
mbx.put(t);
$display("[MON] : Data send to Scoreboard");
@(posedge vif.clk);
end
endtask
endclass   
 
class scoreboard;
mailbox mbx;
transaction t;
bit [7:0] temp; 
 
function new(mailbox mbx);
this.mbx = mbx;
endfunction
 
task run();
t = new();
forever begin
mbx.get(t);
end
endtask
endclass  
 
class environment;
generator gen;
driver drv;
monitor mon;
scoreboard sco;
 
virtual andt_intf vif;
 
mailbox gdmbx;
mailbox msmbx;
 
event gddone;
 
function new(mailbox gdmbx, mailbox msmbx);
this.gdmbx = gdmbx;
this.msmbx = msmbx;
 
gen = new(gdmbx);
drv = new(gdmbx);
 
mon = new(msmbx);
sco = new(msmbx);
endfunction
 
task run();
gen.done = gddone;
drv.done = gddone;
 
drv.vif = vif;
mon.vif = vif;
 
fork 
gen.run();
drv.run();
mon.run();
sco.run();
join_any
 
endtask
 
endclass
 
module tb();
 
environment env;
 
mailbox gdmbx;
mailbox msmbx;
 
andt_intf vif();
 
andt dut ( vif.clk, vif.rst, vif.up, vif.load,  vif.loadin, vif.y );
 
always #5 vif.clk = ~vif.clk;
 
initial begin
vif.clk = 0;
vif.rst = 1;
vif.up = 0;
vif.load = 0;
#20;
vif.load = 1;
#50;
vif.load =0;
#100;
vif.rst = 0;
#100;
vif.up = 1;
#100;
vif.up =0;
end
 
initial begin
gdmbx = new();
msmbx = new();
env = new(gdmbx, msmbx);
env.vif = vif;
env.run();
#500;
$finish;
end
 
endmodule
 