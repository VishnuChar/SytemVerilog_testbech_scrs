`timescale 1ns / 1ps
module Ram_64X8_dut( input clk,
input rst, wr , 
input [7:0] din,
 input [5:0] addr,
 output  reg [7:0] dout
 );
 reg [7:0]mem [63:0];
 integer i;
 always @(posedge clk)
 begin
if(rst==1'b1)
for(i=0;i<64;i++)
begin
mem[i]<=0;
end
else 
begin
 if(wr==1'b1)
 begin
mem[addr]<=din;
end
else
dout<=mem[addr];
end
end
endmodule
class transaction;
rand bit  [7:0]din;
rand  bit [7:0]addr;
bit[7:0] dout;
bit wr;
endclass
class generator;
mailbox mbx;
transaction t;
event done;
integer i;
function new( mailbox mbx);
this.mbx=mbx;
endfunction
task run();
t=new();
for (i=0;i<50;i++)
begin
t.randomize();
mbx.put(t);
$display("[GEN]:Data send to driver");
@(done);
end
endtask
endclass
interface  ram_intf();
logic [7:0] din;
logic [7:0] addr;
logic [7:0] dout;
logic wr,rst,clk;
endinterface
class driver;
mailbox mbx;
transaction t;
event done;
 virtual ram_intf vif;
function new( mailbox mbx);
this.mbx=mbx;
endfunction
task run();
t=new();
forever
begin
mbx.get(t);
vif.din=t.din;
vif.addr=t.addr;
$display("[GEN]:Data triggered");
->done;
@(posedge vif.clk);
end
endtask
endclass
class monitor;
mailbox mbx;
transaction t;
virtual ram_intf vif;
function new( mailbox mbx);
this.mbx=mbx;
endfunction
task run();
t=new();
forever begin
t.din=vif.din;
t.addr=vif.addr;
t.wr=vif.wr;
t.dout=vif.dout;
$display("[mon]:Data sent to SCO");
mbx.put (t);
@(posedge vif.clk);
end
endtask
endclass

class scoreboard;
mailbox mbx;
transaction t;
transaction trr[256];
virtual ram_intf vif;
function new( mailbox mbx);
this.mbx=mbx;
endfunction
task run();
t=new();
forever begin
mbx.get (t);
if(t.wr==1'b1) begin
if (trr[t.addr]==null)begin
   trr[t.addr]=new();
   trr[t.addr]=t;
   $display("[SCO]:Data Stored");
end
end
else begin
if(trr[t.addr]==null) begin
 if(t.dout == 0)begin
$display("[SCO]:Testing passed");
end
 else 
$display("[SCO]:Testing Failed");

end
else begin
if( t.dout==trr[t.addr].din) begin
$display("[SCO]:Testing passed");
end
else
$display("[SCO]:Testing failed");
end
end
end
endtask
endclass
class environment;
generator gen;
driver drv;
monitor mon;
scoreboard sco;
 
virtual ram_intf  vif;
 
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
module Ram_64X8();
environment env;
ram_intf vif();
mailbox gdmbx, msmbx;
 
Ram_64X8_dut uut (vif.clk, vif.rst, vif.wr, vif.din, vif.addr, vif.dout);
 
always #5 vif.clk = ~vif.clk;
 
 
initial begin
vif.clk = 0;
vif.rst = 1;
vif.wr = 1;
#50;
vif.wr = 1;
vif.rst = 0;
#300;
vif.wr = 0;
#200
vif.rst = 0;
#50;
 
end
 
initial begin
gdmbx = new();
msmbx = new();
 
env = new(gdmbx,msmbx);
env.vif = vif;
env.run();
#600;
$finish;
end
endmodule
