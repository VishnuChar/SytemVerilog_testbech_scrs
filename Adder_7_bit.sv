`timescale 1ns / 1ps
module adder_top(
input [7:0] a,
input [7:0] b,
output [8:0] y);
assign y=a+b;
endmodule
class transation;
randc bit [7:0] a;
randc bit [7:0] b;
bit [8:0] y;
endclass
class generator;
transation t;
mailbox mbx;
event done;
integer i;
function new ( mailbox mbx);
this.mbx=mbx;
endfunction
task run();
t=new();
for (i=0;i<20;i++)
begin 
t.randomize();
mbx.put(t);
$display("[GEN]:Data send to driver");
@(done);
#10;
end
endtask
endclass
interface add_int ();
logic[7:0]a;
logic[7:0]b;
logic[8:0]y;
endinterface
class driver;
transation t;
mailbox mbx;
event done;
virtual add_int vif;
function new ( mailbox mbx);
this.mbx=mbx;
endfunction
task run();
t=new();
forever begin
mbx.get(t);
vif.a=t.a;
vif.b=t.b;
$display("[DRV]:Triggered the interface");
-> done;
#10;
end
endtask
endclass
class monitor;
transation t;
virtual add_int vif;
mailbox mbx;
function new ( mailbox mbx);
this.mbx=mbx;
endfunction
task run();
t=new();
forever begin
t.a=vif.a;
t.b=vif.b;
t.y=vif.y;
mbx.put(t);
$display("[MON]:Data send to Scoreboard");
#10;
end
endtask
endclass 
class scoreboard;
transation t;
virtual add_int vif;
mailbox mbx;
bit [8:0] temp;
function new ( mailbox mbx);
this.mbx=mbx;
endfunction
task run();
t=new();
forever begin
mbx.get(t);
temp=t.a+t.b;
if (temp== t.y)
begin
$display("[SCO]:Test passed ");
end
else
begin
$display("[SCO]:Test failed ");
end
#10;
end
endtask
endclass 
class enviroment;
virtual add_int vif;
generator gen;
driver drv;
monitor mon;
scoreboard sco;
mailbox gdmbx;
mailbox msmbx;
event gddone;
function new ( mailbox gdmbx, mailbox msmbx);
this.gdmbx=gdmbx;
this.msmbx= msmbx;
gen=new(gdmbx);
drv=new(gdmbx);
mon=new(msmbx);
sco=new(msmbx);
endfunction
task run();
gen.done=gddone;
drv.done=gddone;
drv.vif=vif;
mon.vif=vif;
fork
gen.run();
drv.run();
mon.run();
sco.run();
join_any 
endtask
endclass
module Adder_7_bit();
enviroment env;
mailbox gdmbx,msmbx;
add_int vif ();
adder_top uut (
vif.a,
vif. b,
vif. y);
initial begin
gdmbx=new();
msmbx=new();
env=new(gdmbx,msmbx);
env.vif=vif;
env.run();
#200;
$finish;
end
endmodule
