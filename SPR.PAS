{*******************************************************}
{                                                       }
{       Unidad SPR                                      }
{       Creada por Luis Parravicini, 22/07/1995.        }
{                                                       }
{                                                       }
{*******************************************************}

Unit Spr;

Interface

Type
    Img = Record
      Data: Pointer;
      MaxX, MaxY: Integer
    End;

    GChr = Array [0..7] of Byte;

Var
   Font: Array [0..255] of GChr;
   Vid: Img;


Procedure CopyImg(Desde, Hasta: Img; X0, Y0, X1, Y1, W, H, Invs: Integer);
  { Copia la imagen que apunta Desde.Data en la posici¢n (X0,Y0) hasta }
  {   Hasta.Data en la posici¢n (X1,Y1)-(X1+W,Y1+H). Invs es el color  }
  {   usado para invisibilidad (-1 si no se usa).                      }

Procedure GWriteXY(X, Y: Integer; S: String; Color, Fondo: Byte);
  { Escribe en (X,Y) la cadena S (se debe antes haber cargado alg£n font). }

Procedure ChgFont;
  { Pone como font activo al que se encuentra en el arreglo Font. }

Implementation

Procedure CopyImg(Desde, Hasta: Img; X0, Y0, X1, Y1, W, H, Invs: Integer);
  { Copia la imagen que apunta Desde.Data en la posici¢n (X0,Y0) hasta }
  {   Hasta.Data en la posici¢n (X1,Y1)-(X1+W,Y1+H). Invs es el color  }
  {   usado para invisibilidad (-1 si no se usa).                      }
label
  _Redraw, _DrawLoop, _Exit, _LineLoop, _NextLine, _Store, _NoPaint;
Var
   Orig, Dest: ^Byte;
   I: Integer;
Begin
     Orig:=Desde.Data; Inc(Orig, Y0*Desde.MaxX+X0);
     Dest:=Hasta.Data; Inc(Dest, Y1*Hasta.MaxX+X1);
     If Invs=-1 then
       For I:=1 to H do begin
         Move(Orig^, Dest^, W);
         Inc(Orig, Desde.MaxX);
         Inc(Dest, Hasta.MaxX);
       End
     else
         Asm
            push  ds
            push  es
            lds   si,Orig
         _Redraw:
            les   di,Dest
            mov   cx,W          { cx = ancho de la imagen a copiar }
            mov   dx,H          { dx = alto de la imagen a copiar }
            cld
            sub   bh,bh
         _DrawLoop:
            push  di            { store y adr. for later }
            push  si
            push  cx            { store width }
         _LineLoop:
            mov   bl,byte ptr [si]
            cmp   bx,Invs
            jnz   _Store
         _NoPaint:
            inc    si
            inc    di
            loop   _LineLoop
            jmp    _NextLine
         _Store:
            movsb
            loop   _LineLoop
         _NextLine:
            pop   cx
            pop   si
            pop   di
            dec   dl
            jz    _Exit
            add   di,Hasta.MaxX        { di = proxima linea en destino }
            add   si,Desde.MaxX        { si = proxima linea en origen  }
            jmp   _DrawLoop
         _Exit:
            pop   es
            pop   ds
         End;
End;

Procedure GWriteXY(X, Y: Integer; S: String; Color, Fondo: Byte);
  { Escribe en (X,Y) la cadena S (se debe antes haber cargado alg£n font). }
var
   I: Byte;
   Scr, Letra: Img;
Procedure Convrt_Fnt_a_Spr(LChar: Img; Letra: GChr; Color, Fondo: Byte);
const
     ala : array [0..7] of byte = (128, 64, 32, 16, 8, 4, 2, 1);
Var
   I, J: Byte;
   A: ^Byte;
Begin
     A:=LChar.Data;
     For I:=0 to 7 do
       For J:=0 to 7 do begin
         If (ala[J] and Letra[I]) = ala[J] then A^:=Color
         else
           A^:=Fondo;
         Inc(A);
       End;
End;

Begin
     GetMem(Letra.Data, 64);
     Letra.MaxX:=8;
     Letra.MaxY:=8;
     Scr.Data:=Ptr($A000, 0);
     Scr.MaxX:=320;
     Scr.MaxY:=200;
     For I:=1 to Length(S) do begin
       Convrt_Fnt_a_Spr(Letra, Font[Ord(S[I])], Color, Fondo);
       CopyImg(Letra, Scr, 0, 0, X+I*Letra.MaxX, Y, Letra.MaxX, Letra.MaxY, -1);
     End;
     FreeMem(Letra.Data, 64);
End;

Procedure ChgFont; Assembler;
  { Pone como font activo al que se encuentra en el arreglo Font. }
Asm                                
   push bp
   mov  ax,seg(@DATA)
   mov  es,ax
   mov  bp,offset Font
   mov  bl,2
   mov  cx,8
   mov  ax,1121h
   int  10h
   pop  bp
End;

Begin
     With Vid do begin
       Data:=Ptr($A000, 0);
       MaxX:=320;
       MaxY:=200;
     End;
End.
