{
  Copyright 1995 Luis Parravicini <xrm0@ktulu.com.ar>
}
uses crt,colores;

Procedure ShiftColorsRight(Prim, Ult: Byte);
Var
   I: Byte;
   Col,Col1: RGB;
Begin
     GetRGBColor(Prim, Col);
     For I:=Prim+1 to Ult do begin
       GetRGBColor(I, Col1);
       PutRGBColor(I, Col);
       Col:=Col1;
     End;
     PutRGBColor(Prim, Col);
End;

Procedure ShiftColorsLeft(Prim, Ult: Byte);
Var
   I: Byte;
   Col,Col1: RGB;
Begin
     GetRGBColor(Ult, Col);
     For I:=Ult-1 downto Prim do begin
       GetRGBColor(I, Col1);
       PutRGBColor(I, Col);
       Col:=Col1;
     End;
     PutRGBColor(Ult, Col);
End;

var
   x,y,i: integer;
   f: file;
   a: paleta;
begin
     asm
        mov ax,13h
        int 10h
     end;
     assign(f,'records.cel');
     reset(f,1);
     seek(f,2); blockread(f, x, 2); blockread(f, y, 2);
     seek(f,32); blockread(f, a, 768); restorepaleta(a,255);
     for i:=1 to y do blockread(f, ptr($A000,i*320)^, x);
     close(f);
     i:=0;
     while not keypressed do begin
       inc(i);
       if i<=6 then ShiftColorsRight(64,70)
       else
         ShiftColorsLeft(64,70);
       if i=12 then i:=0;
       delay(140);
     end;
     readln;
     asm
        mov ax,3
        int 10h
     end;
end.