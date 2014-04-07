{
  Copyright 1995 Luis Parravicini <xrm0@ktulu.com.ar>
}
unit multitec;

interface
{$X+}

uses dos, crt;

var
   presionada: array [0..127] of boolean;

procedure instalarmt;
procedure desinstalarmt;

implementation

var
   anterior: procedure;
   anteriorexit: pointer;

{$F+}
procedure teclado; interrupt;
var
   p60: byte;
begin
     p60:=port[$60];
     if p60>127 then presionada[p60-128]:=false
       else presionada[p60]:=true;
     while keypressed do
       readkey;
     inline($9C);
     anterior;
end;
procedure desinstalarmt;
begin
     setintvec(9,@anterior);
     release(anteriorexit);
end;
{$F-}

procedure instalarmt;
begin
     fillchar(presionada, sizeof(presionada), false);
     getintvec(9,@anterior);
     setintvec(9,@teclado);
end;

begin
     anteriorexit:=@exitproc;
     exitproc:=@desinstalarmt;
     instalarmt;
end.