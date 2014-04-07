{
  Copyright 1995 Luis Parravicini <xrm0@ktulu.com.ar>
}

{$X+}
uses crt,colores,misctool;

type
    gchr = array [1..8] of byte;
var
   fonts: array [0..255] of gchr;

Procedure WriteChr(C, Color: Byte);
Begin
     Asm
        mov  ah,0Fh
        int  10h
        mov  cx,1
        mov  al,C
        mov  bl,Color
        mov  ah,9
        int  10h
     End;
     GotoXY(WhereX+1, WhereY);
End;

Procedure WriteStr(X, Y, MaxX: Byte; S: String; Color: Byte);
Var
   I: Byte;
Begin
     GotoXY(X, Y);
     For I:=1 to Length(S) do begin
       WriteChr(Ord(S[I]), Color);
       If WhereX>MaxX then GotoXY(X, WhereY+1);
     End;
End;

procedure loadfont;
var
   f: file;
begin
     assign(f,'8.FNT');
     reset(f,1);
     blockread(f, fonts, sizeof(fonts));
     close(f);
     asm
        push es
        push bp
        mov  ax,seg(@DATA)
        mov  es,ax
        mov  bp,offset fonts
        mov  bl,2
        mov  cx,8
        mov  ax,1121h
        int  10h
        pop  bp
        pop  es
     end;
end;

begin
     asm
        mov  ax,13h
        int  10h
     end;
     writestr(1,1,40,'ABCDEFGHIJKLMNOPQRSTUVWXYZ',15);
     writestr(1,2,40,'abcdefghijklmnopqrstuvwxyz',15);
     writestr(1,3,40,'0123456789',15);
     loadfont;
     writestr(1,5,40,'ABCDEFGHIJKLMNOPQRSTUVWXYZ',15);
     writestr(1,6,40,'abcdefghijklmnopqrstuvwxyz',15);
     writestr(1,7,40,'0123456789',15);
     readln;
     textmode(CO80);
end.