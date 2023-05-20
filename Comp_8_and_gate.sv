`timescale 1ns / 1ps
module top_and( input [7:0] a,
input [7:0] b, output [7:0] y );
assign y=a&b;
endmodule
class transation;
randc bit [7:0] a;
randc bit [7:0] b;
bit [7:0] y;
endclass
class generator;
transation t;
mailbox mbx;
event done;
integer i;
function new (mailbox mbx);
this.mbx=mbx;
endfunction
task run();
t=new();
for(i=0; i<20;i++)
begin
t.randomize();
mbx.put(t);
$display("[GEN]:Data send TO driver");
@(done);
#10;
end
endtask
endclass
interface and_intf ();
logic [7:0] a;
logic [7:0] b;
logic [7:0] y;
endinterface
class driver ;
transation t;
virtual and_intf vif;
mailbox mbx;
event done;
function new (mailbox mbx);
this.mbx = mbx;
endfunction
task run();
t=new();
forever begin
mbx.get(t);
vif.a=t.a;
vif.b=t.b;
$display("[DRV]:Triggered the Interface");
->done;
#10;
end
endtask
endclass
class monitor;
transation t;
virtual and_intf vif;
mailbox mbx;
function new (mailbox mbx);
this.mbx = mbx;
endfunction 
task run();
t=new();
forever begin
t.a=vif.a;
t.b=vif.b;
t.y=vif.y;//transactions of the all the varbles need to be transmitted
mbx.put(t);
$display("[DRV]:Data Sent to scoreboard");
#10;
end
endtask
endclass
class scoreboard;
transation t;
virtual and_intf vif;
mailbox mbx;
bit [7:0] temp;
function new (mailbox mbx);
this.mbx = mbx;
endfunction 
task run();
t=new();
forever begin
temp =t.a&t.b;
if ( t.y==temp)
begin
$display(" [SCO]Test passed");
#10;
end
else 
begin 
$display("[SCO]Test Failed");
#10;
end
end
endtask
endclass
class enviroment;
generator gen;
driver drv;
monitor mon;
scoreboard sco;
virtual and_intf vif;
mailbox gdmbx;
mailbox msmbx;
event gddone; 
function new( mailbox gdmbx, mailbox msmbx);
this.gdmbx=gdmbx;
this.msmbx=msmbx;
gen= new(gdmbx);
drv =new(gdmbx);
mon =new(msmbx);
sco =new(msmbx);
endfunction
task run();
gen.done=gddone;
drv.done=gddone;
drv.vif=vif;// connetcting all the interfaces as same type
mon.vif=vif;
fork 
gen.run();
drv.run();
mon.run();
sco.run();
join_any
endtask
endclass
module Comp_8_and_gate();
enviroment env;
and_intf vif();
top_and uut ( vif. a,
vif. b, vif. y );
mailbox gdmbx;
mailbox msmbx;
initial begin
gdmbx=new();
msmbx=new();
env =new(gdmbx,msmbx);
env.vif=vif;
env.run();
#200;
$finish;
end
endmodule
