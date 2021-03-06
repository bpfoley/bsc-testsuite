// if wire was set this cycle, then bypass, otherwise
//   use value stored in register
interface BypassReg#(type tp);
   method Action _write( tp v );
   method tp     _read();
   method tp     regonly();
endinterface

// Note: THIS IMPLEMENTATION IS BORKED!
// The write and read methods are in conflict!
module mkBypassReg( BypassReg#( typ ) ) provisos( Bits#(typ,szN) );
   Reg#(typ)   rg <- mkRegU;   
   RWire#(typ) wr <- mkRWire;

   method Action _write( typ v );
      wr.wset( v );
      rg <= v;   
   endmethod

   method typ _read();
      if (wr.wget matches tagged Valid .v) 
         return v;
      else
         return rg;
   endmethod

   method typ regonly() = rg;

endmodule

// Create a module with a rule that writes to the BypassReg
// and a value method that reads from it.
interface Bug;
  method Bool get();
endinterface

(* synthesize *)
module mkBug(Bug);

  BypassReg#(Bool) r <- mkBypassReg();

  // the get() method conflicts with this rule,
  // and is always enabled because it is a value method,
  // so this rule will never fire.
  rule put;
    r <= True;
  endrule

  method Bool get() = r;

endmodule

(* synthesize *)
module sysValueMethodPreemptsRule();

  Bug b <- mkBug();

  rule test;
    $display("%b", b.get());
    $finish(0);
  endrule

endmodule