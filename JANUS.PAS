{
 Copyright 1995 Luis Parravicini <xrm0@ktulu.com.ar>
}
{$X+}
uses crt,colores,misctool,spr,input,libreria
{$IFNDEF Debuggeando}
  ,multitec
{$ENDIF}
;
{$IFDEF Debuggeando}
 var
   presionada:array [1..127] of boolean;
{$ENDIF}

const
     f10 = 68;
     fin = 1;
     izq = 75;
     der = 77;
     barra = 57;
     maxbuff = 15000;
     maxs = 49;
     FDatos = 'janus.dat';
Type
    Cad20 = String[20];

    highs = record
      nombre: Cad20;
      puntaje: word;
    end;

    pdata = array [1..maxbuff] of byte;
    cel = record
      maxx,maxy: word;
      data: ^pdata;
    end;

    scr = array [1..64000] of byte;
var
   records: array [1..10] of highs;
   frecords: file;
   sprites: array [1..maxs] of cel;
   muerto: array [1..9, 1..5] of boolean;
   palette: paleta;
   fondo,menuscr: ^scr;
   x,y: integer;
   xb,yb: integer;
   ox,oy: integer;
   f,c,c2: byte;
   dere: boolean;
   puntaje: word;
   vidas, nivel: byte;
   salir,finjuego,jugando: boolean;
   datos: lib;

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

Function Menor(X, Y: Integer): Integer;
Begin
     If X>Y then
       Menor:=Y
     else
       Menor:=X;
End;

Function Mayor(X, Y: Integer): Integer;
Begin
     If X>Y then
       Mayor:=X
     else
       Mayor:=Y;
End;
{----------------------------------------------------------------------------}
{
{                            Parte grafica
{
{----------------------------------------------------------------------------}

procedure initgraphics;
begin
     asm
        mov   ax,$13
        int   $10
     end;
     if mem[0:$449]<>$13 then begin
       writeln('Se necesita monitor VGA para poder correr el programa');
       halt(1)
     end;
end;

procedure borra(x1,y1,x2,y2: integer);
var
   i: integer;
begin
     for i:=y1 to y2 do
       move(fondo^[i*320+x1+1], ptr($A000, i*320+x1)^, x2-x1);
end;

procedure dibuja(i: byte; x, y: integer; borra: byte);

procedure borraspr(datos: pointer; x, y, maxx, maxy: integer); assembler;
label
  _Redraw, _DrawLoop, _Exit, _NextLine, _Store, _NoPaint, _DontInc;
asm
    push  ds
    push  es
    lds   si,datos
    mov   ax,x                  { ax = x }
    mov   bx,y                  { bx = y }
_Redraw:
    push  ax
    push  bx
    mov   ax,$A000
    mov   es,ax         { ES=A000h }
    pop   bx            { ax = y }
    mov   ax,320
    mul   bx            { ax = y * 320 }
    pop   bx            { ax = x }
    add   ax,bx         { bx = bx + ax dvs. skjermadr.. }
    mov   di,ax         { di = skjermadr. }
    mov   dx,maxy       { dl = height of sprite }
    mov   cx,maxx       { cx = width of sprite }
    add   si,di         { si = start of spritedata (se supone que   }
                        {      datos apunta a una pantalla virtual) }
    cld
_DrawLoop:
    push  di            { store y adr. for later }
    push  cx            { store width }
_Store:
{    test   byte ptr [es:di],1
    jz     _NoPaint}
    movsb
    jmp    _DontInc
{_NoPaint:
    inc    si
    inc    di}
_DontInc:
    loop   _Store
_NextLine:
    pop   cx
    pop   di
    dec   dl
    jz    _Exit
    add   di,320        { di = next line of sprite }
    jmp   _DrawLoop
_Exit:
    pop   es
    pop   ds
end;

procedure dibujaspr(datos: pointer; x, y: integer); assembler;
label
  _Redraw, _DrawLoop, _Exit, _LineLoop, _NextLine, _Store, _NoPaint;
asm
    push  ds
    push  es
    lds   si,datos
    mov   ax,x                  { ax = x }
    mov   bx,y                  { bx = y }
_Redraw:
    push  ax
    push  bx
    mov   ax,$A000
    mov   es,ax         { ES=A000h }
    pop   bx            { ax = y }
    mov   ax,320
    mul   bx            { ax = y * 320 }
    pop   bx            { ax = x }
    add   ax,bx         { bx = bx + ax dvs. skjermadr.. }
    mov   di,ax         { di = skjermadr. }
    mov   dl,[si+2]     { dl = height of sprite }
    xor   ch,ch
    mov   cl,[si]       { cx = width of sprite }
    add   si,4          { si = start of spritedata }
    lds   si, [si]
    cld
_DrawLoop:
    push  di            { store y adr. for later }
    push  cx            { store width }
_LineLoop:
{    mov   bl,byte ptr [si]
    cmp   bl,255
    jnz   _Store
_NoPaint:
    inc    si
    inc    di
    loop   _LineLoop
    jmp    _NextLine}
_Store:
{    test   byte ptr [es:di],1
    jz     _NoPaint}
    movsb
    loop  _LineLoop
_NextLine:
    pop   cx
    pop   di
    dec   dl
    jz    _Exit
    add   di,320        { di = next line of sprite }
    jmp   _DrawLoop
_Exit:
    pop   es
    pop   ds
end;

begin
     case borra of
       0:dibujaspr(addr(sprites[i]), x, y);
       1:borraspr(fondo, x, y, sprites[i].maxx, sprites[i].maxy);
     end;
end;

procedure box(x1,y1,x2,y2: integer; fondo, borde1, borde2: byte);
var
   i: integer;
begin
     fillchar(ptr($A000,y1*320+x1)^, x2-x1, borde1);
     for i:=y1+1 to y2 do begin
       mem[$A000:i*320+x1]:=borde1;
       fillchar(ptr($A000,i*320+x1+1)^, x2-x1-2, fondo);
       mem[$A000:i*320+x2-1]:=borde2;
     end;
     fillchar(ptr($A000,y2*320+x1+1)^, x2-x1-1, borde2);
end;

Procedure EditaCadena(X, Y: Integer; var S: Cad20; Color, Fondo: Byte);
Var
   Posi: Byte;
   Tecla: Word;
Begin
     GWriteXY(X, Y, S+'_', Color, Fondo);
     Posi:=Length(S)+1;
     Repeat
           Tecla:=GetKey;
           Case Tecla of
             BS: If Posi>1 then begin
                   Delete(S, Length(S), 1);
                   GWriteXY(X, Y, S+'_ ', Color, Fondo);
                   Dec(Posi);
                 End;
             32..255: If Posi<21 then begin
                        S:=S+Chr(Tecla);
                        GWriteXY(X, Y, S+'_', Color, Fondo);
                        Inc(Posi);
                      End;
           End;
     Until Tecla in [Esc, CR];
     GWriteXY(X, Y, S+' ', Color, Fondo);
End;
{[]========================================================================[]}
{                               Records                                      }
{[]========================================================================[]}
Procedure Graba_Records;
Begin
     Assign(FRecords, 'RECORDS.DAT');
     ReWrite(FRecords, Sizeof(Records[1]));
     BlockWrite(FRecords, Records, 10);
     Close(FRecords);
End;

procedure Ver_Records(movcol: byte);
Var
   I: Byte;
   S: String;
   Aux: Img;
Begin
     With Aux do begin
       MaxX:=285-45+1;
       MaxY:=192-36+1;
       GetMem(Data, MaxX*MaxY);
     End;
     CopyImg(Vid, Aux, 45, 36, 0, 0, Aux.MaxX, Aux.MaxY, -1);
     Box(45, 36, 285, 192, 1, 236, 249);
     Dibuja(49, 138, 44, 0);
     For I:=1 to 10 do begin
       GWriteXY(50, 54+I*12, Records[I].Nombre, 224-I, 1);
       Str(Records[I].Puntaje:5, S);
       GWriteXY(230, 54+I*12, S, 224-I, 1);
     End;
     If MovCol=1 then begin
       I:=0;
       While Not KeyPressed do begin
         Inc(I);
         If I<=6 then ShiftColorsRight(64,70)
         else
           ShiftColorsLeft(64,70);
         If I=12 then I:=0;
         Delay(140);
       End;
       CopyImg(Aux, Vid, 0, 0, 45, 36, Aux.MaxX, Aux.MaxY, -1);
     End;
     With Aux do FreeMem(Data, MaxX*MaxY);
End;

Procedure Ingresa_Record;
Var
   I,J: Byte;
   S: String;
   Aux: Img;
Begin
     I:=1;
     While (I<11) and (Records[I].Puntaje>Puntaje) do Inc(I);
     If (I <= 10) then begin
       With Aux do begin
         MaxX:=285-45+1;
         MaxY:=192-36+1;
         GetMem(Data, MaxX*MaxY);
       End;
       CopyImg(Vid, Aux, 45, 36, 0, 0, Aux.MaxX, Aux.MaxY, -1);
       Ver_Records(0);
       For J:=10 downto I+1 do
         Records[J]:=Records[J-1];
       Ver_Records(0);
       Records[I].Puntaje:=Puntaje;
       Str(Puntaje:5, S);
       GWriteXY(50, 54+I*12, ConstStr(' ', 20), 1, 1);
       GWriteXY(230, 54+I*12, S, 8, 1);
       Records[I].Nombre:='';
       EditaCadena(50, 54+I*12, Records[I].Nombre, 8, 1);
       GWriteXY(50, 54+I*12, Records[I].Nombre, 224-I, 1);
       GWriteXY(230, 54+I*12, S, 224-I, 1);
       Graba_Records;
       CopyImg(Aux, Vid, 0, 0, 45, 36, Aux.MaxX, Aux.MaxY, -1);
       With Aux do FreeMem(Data, MaxX*MaxY);
     End;
End;

Procedure Nuevos_Records;
Var
   I: Byte;
   Acum: Word;
Begin
     Acum:=0;
     I:=10;
     While (I > 0) do begin
       Records[I].Nombre:='Luis Parravicini';
       Records[I].Puntaje:=Acum;
       Inc(Acum, 5000);
       Dec(I)
     End;
End;

procedure lee_records;
begin
     assign(frecords, 'RECORDS.DAT');
     {$I-}; reset(frecords, 1); {$I+}
     if (ioresult<>0) or (filesize(frecords)<>sizeof(records[1])*10) then begin
       Nuevos_Records;
       rewrite(frecords, Sizeof(Records[1]));
       blockwrite(frecords, records, 10);
     end else
       blockread(frecords, records, Sizeof(Records[1])*10);
     close(frecords);
end;

{----------------------------------------------------------------------------}
{
{
{
{----------------------------------------------------------------------------}
procedure libera_mem;
var
   i: byte;
begin
     for i:=1 to maxs do
       if sprites[i].data<>NIL then
         freemem(sprites[i].data, sprites[i].maxx*sprites[i].maxy);
     if fondo <> NIL then freemem(fondo, sizeof(fondo^));
end;

procedure malloc(var p; size: word; var f: file; cierra: byte);
var
   p1: pointer;
begin
     if maxavail<size then begin
       libera_mem;
       if cierra = 1 then close(f);
       textmode(CO80);
       writeln('No hay suficiente memoria');
       halt(8);
     end;
     getmem(p1, size);
     move(p1, p, 4);
end;

Procedure ChkForErrors;
Begin
     If (Datos.Error <> 0) then begin
       libera_mem;
       textmode(CO80);
       Case Datos.Error of
           2:writeln('No puedo encontrar a '+FDatos);
           3:writeln('Handle inv lido.');
           4:writeln('Archivo corrupto.');
           8:writeln('No hay suficiente memoria.');
         100:writeln('Error de lectura.');
       End;
       Halt(Datos.Error);
     End;
End;

procedure loadcels;
const
     archivos: array [1..maxs] of string[8] = ('BALA',
       'BALAENEM','ENEM11','ENEM12','ENEM21','ENEM22','ENEM31','ENEM32',
       'ENEM41','ENEM42','ENEM51','ENEM52','EXPLOSIO','NAVE','N','I','V','E',
       'L','CURSOR','VIDA','ULTVIDA','0','1','2','3','4','5','6','7','8','9',
       '0S','1S','2S','3S','4S','5S','6S','7S','8S','9S','IS','VS','XS',
       'GMOVER1','GMOVER2','MENU','RECORDS');
var
   I: Byte;
   H: Word;
begin
     for i:=1 to maxs do begin
       Datos.BuscaHandle(Archivos[I]+'.CEL', H);
       ChkForErrors;
       Sprites[I].MaxX:=Datos.Archs[H].MaxX;
       Sprites[I].MaxY:=Datos.Archs[H].MaxY;
       Datos.LeeArch(H, Pointer(Sprites[I].Data), 1);
       ChkForErrors;
     end;
end;

Procedure CargaPaleta;
Var
   H: Word;
   P: Pointer;
Begin
     Datos.BuscaHandle('PALETA.COL', H);
     ChkForErrors;
     P:=@Palette;
     Datos.LeeArch(H, P, 0);
     restorepaleta(palette,255);
End;


procedure init_tablero;
begin
     fillchar(muerto, sizeof(muerto), 0);
end;

Procedure LoadFondo;
Var
   H: Word;
Begin
     Datos.BuscaHandle('FONDO.CEL', H);
     ChkForErrors;
     Datos.LeeArch(H, Pointer(Fondo), 1);
     Move(Fondo^, Vid.Data^, 64000);
End;

function todos_muertos: boolean;
var
   i,j: byte;
   a: boolean;
begin
     a:=true;
     for j:=1 to 5 do
       for i:=1 to 9 do
         if not muerto[i,j] then a:=false;
     todos_muertos:=a;
end;

procedure init_vars;
begin
     ox:=30;
     oy:=20;
     f:=0;
     c:=0;
     dere:=true;
     c2:=0;
     if x<>-1 then xb:=-1;
end;

procedure muestra_tablero(oldx, oldy, x, y: integer; forma: byte);
var
   i,j,k: integer;
   p: pointer;
   scr,sprit: img;
begin
     getmem(p,(abs(oldx-x)+29*9)*(abs(oldy-y)+18*5));

     { Copio el fondo a P }
     scr.data:=p;
     scr.maxx:=abs(oldx-x)+29*9;
     scr.maxy:=abs(oldy-y)+18*5;
     sprit.data:=fondo;
     sprit.maxx:=320;
     sprit.maxy:=200;
     CopyImg(sprit, scr, menor(oldx,x), menor(oldy, y), 0, 0,
       abs(oldx-x)+29*9, abs(oldy-y)+18*5, -1);

     { Copio los sprites a P }
     for j:=0 to 4 do
       for i:=0 to 8 do begin
         k:=3;
         if forma = 0 then begin
           if i mod 2 <> 0 then inc(k)
         end else
           if i mod 2 = 0 then inc(k);
         k:=k+2*(j+1)-2;
         if j*18+y+sprites[k].maxy<=200 then begin
           if not muerto[i+1,j+1] then begin
             sprit.data:=sprites[k].data;
             sprit.maxx:=sprites[k].maxx;
             sprit.maxy:=sprites[k].maxy;
             CopyImg(Sprit, Scr, 0, 0, i*29+x-oldx,
               j*18+y-oldy, Sprit.Maxx, Sprit.Maxy, 0);
           End;
         end;
       end;

     { Copio P a la pantalla }
     If (Menor(OldY, Y) + Abs(OldY - Y) + 18*5 > 200) then
       I:=200 - Menor(OldY, Y)
     else
       I:=Abs(Oldy - Y) + 18*5;
     CopyImg(scr, vid, 0, 0, menor(oldx,x), menor(oldy, y),
       abs(oldx-x)+29*9, I, -1);

     FreeMem(p,(abs(oldx-x)+29*9)*(abs(oldy-y)+18*5));
end;

procedure muestra_status;
var
   j,k: integer;
   s,s1: string;

function romanos(ch: char; unidad: byte): string;
var
   s: string;
begin
     s:='';
     if unidad = 1 then
       case ch of
         '1'..'3':s:=conststr('I', ord(ch)-48);
         '4':s:='IV';
         '5'..'8':s:='V'+conststr('I',ord(ch)-53);
         '9':s:='IX';
       end
     else
       case ch of
         '1'..'3':s:=conststr('X', ord(ch)-48);
       end;
     romanos:=s;
end;

begin
     str(puntaje:6, s);
     borra(75, 6, 111, 10);
     for j:=1 to 6 do
       if s[j] = ' ' then dibuja(33, 75+j*6, 6, 0)
       else
         dibuja(33+ord(s[j])-48, 75+j*6, 6, 0);
     borra(175, 6, 229, 10);
     for j:=1 to vidas do
       if j = 1 then dibuja(22, 175+j*6, 6, 0)
       else
         dibuja(21, 175+j*6, 6, 0);
     borra(269, 6, 314, 10);
     str(nivel:2, s);
     s1:=romanos(s[1], 2)+romanos(s[2], 1);
     for j:=1 to length(s1) do begin
       case s1[j] of
         'I':k:=43;
         'V':k:=44;
         'X':k:=45;
       end;
       dibuja(k, 263+j*6, 6, 0)
     end;
end;

Procedure Game_Over;
Var
   I, J, K: Integer;
Begin
     finjuego:=true;
     borra(0, 16, 0, 200);
     dibuja(46, 71, 79, 0);
     i:=1;
     while i<=sprites[47].maxy do begin
       j:=sprites[47].maxy-i;
       for k:=1 to i do begin
         move(sprites[47].data^[j*sprites[47].maxx+1],
         ptr($A000, (83+k)*320+90)^, sprites[47].maxx);
         inc(j);
       end;
       delay(15);
       inc(i);
     end;
     for i:=1 to 10 do begin
       for k:=1 to i do
         move(sprites[47].data^[1], ptr($A000, (83+k)*320+90)^,
           sprites[47].maxx);
       dibuja(47, 90, 83+i, 0);
       delay(10);
     End;
End;

procedure mueve_bala;
var
   i,j: integer;
begin
     dec(yb);
     dibuja(1, xb, yb, 0);
     if (mem[$A000:yb*320+xb]<>0) or (mem[$A000:yb*320+xb+1]<>0) or
       (mem[$A000:yb*320+xb+2]<>0) then begin
       j:=yb-oy;
       if j mod 18 <> 0 then j:=succ(j div 18)
       else
         j:=j div 18;
       i:=xb-ox;
       if i mod 29 <> 0 then i:=succ(i div 29)
       else
         i:=i div 29;
       if (j<=5) and (j>0) and (i<=9) and (i>0) and not muerto[i,j] then begin
         dibuja(1, xb, yb, 1);
         muerto[i,j]:=true;
         dibuja(13, i*29-29+ox, j*18-18+oy, 0);
         delay(50);
         dibuja(13, i*29-29+ox, j*18-18+oy, 1);
         xb:=-1;
         inc(puntaje, (6-j)*5);
         muestra_status;
       end;
     end;
     if yb=16 then begin
       dibuja(1, xb, yb, 1);
       xb:=-1;
     end;
end;

procedure mueve_enemigos;
var
   i,j,k: integer;
   a: boolean;
   oldox, oldoy: integer;
begin
     oldox:=ox;
     oldoy:=oy;
     c:=0;
     if dere then inc(ox,4)
     else
       dec(ox,4);
     if ox<=0 then begin
       dere:=true;
       ox:=0;
     end;
     if ox>=60 then begin
       dere:=false;
       ox:=60;
     end;
     if oy+5*18>y then begin
       a:=false;
       j:=6;
       while (j<>0) and not a do begin
         dec(j);
         i:=1;
         while (i<=9) and not a do begin
           if not muerto[i,j] then a:=true;
           inc(i);
         end;
       end;
       if oy+j*18>y then begin
         init_vars; f:=1;
         oldox:=ox;
         oldoy:=oy;
         dec(vidas);
         If (Vidas = 0) then Game_Over;
         sound(5000); delay(5); nosound;
         delay(4000);
         move(fondo^[16*320], ptr($A000,16*320)^, 64000-16*320);
         x:=135;
         y:=180;
         dibuja(14, x, y, 0);
         muestra_status;
         init_tablero;
       end;
     end;
     If (Vidas <> 0) then begin
       inc(c2);
       if c2=5 then begin
         inc(oy,5);
         c2:=0;
       end;
       inc(f); if f>1 then f:=0;
       muestra_tablero(oldox, oldoy, ox, oy, f);
     End;
end;

procedure pasa_de_nivel;
var
   i: integer;
   s: string;
begin
     inc(nivel);
     If (Nivel = 21) then begin
       GWriteXY(72, 50, 'Fin de la versi¢n demo', 23, 0);
       GWriteXY(40, 80, 'Por falta de tiempo no se pudo', 23, 0);
       GWriteXY(56, 90, 'hacer la final del juego.', 23, 0);
       While Not KeyPressed do;
       While KeyPressed do ReadKey;
       FinJuego:=True;
       Jugando:=False;
     end else begin
       init_tablero;
       init_vars; f:=1;
       muestra_status;
       move(fondo^[16*320+1], ptr($A000,16*320)^, 64000-16*320);
       dibuja(14, x, y, 0);
       for i:=1 to 5 do begin
         dibuja(20,  100+i*9, 110, 0);
         delay(200);
         dibuja(20,  100+i*9, 110, 1);
         dibuja(14+i, 100+i*9, 110, 0);
       end;
       inc(i);
       dibuja(20,  100+i*9, 110, 0);
       delay(200);
       dibuja(20,  100+i*9, 110, 1);
       str(nivel:2, s);
       for i:=8 to 9 do begin
         dibuja(20,  100+i*9, 110, 0);
         delay(200);
         dibuja(20,  100+i*9, 110, 1);
         if s[i-7] = ' ' then dibuja(23, 100+i*9, 110, 0)
         else
           dibuja(23+ord(s[i-7])-48, 100+i*9, 110, 0)
       end;
       delay(3000);
       for i:=110 to 120 do
         move(fondo^[i*320+109], ptr($A000,i*320+109)^, 81);
       muestra_tablero(ox, oy, ox, oy, f);
     End;
End;

procedure jugar;
{$IFDEF Debuggeando}
var
   p60: byte;
{$ENDIF}
begin
     if not jugando then begin
       Borra(0, 20, 320, 200);
       init_vars;
       FillChar(Muerto, Sizeof(Muerto), 0);
       muestra_tablero(ox, oy, ox, oy, f);
       x:=135;
       y:=180;
       puntaje:=0;
       vidas:=5;
       nivel:=1;
       muestra_status;
       finjuego:=false;
       jugando:=true;
     end;
     repeat
{$IFDEF Debuggeando}
  if keypressed then begin
    p60:=port[$60];
    if p60>127 then presionada[p60-128]:=false
      else presionada[p60]:=true;
    while keypressed do
      readkey;
  end;
{$ENDIF}

           delay(2);
           dibuja(14, x, y, 0);
           if presionada[izq] and (x>1) then dec(x);
           if presionada[der] and (x<295) then inc(x);
           if presionada[barra] and (xb=-1) then begin
             xb:=x+11;
             yb:=y-9;
           end;
           if xb<>-1 then mueve_bala;
           if presionada[f10] then fillchar(muerto, sizeof(muerto), 1);
           inc(c);
           if c>25 then mueve_enemigos;
           if todos_muertos then pasa_de_nivel;
     until finjuego or presionada[fin];
     jugando:=not finjuego;
     if finjuego then Ingresa_Record;
end;

function menu: byte;
var
   op: char;
begin
     box(82,50,237,175, 1, 236, 249);
     dibuja(48, 107, 65, 0);
     repeat
           op:=upcase(readkey);
           If (Op = 'T') and (Not Jugando) then Op:=#0;
     until op in ['C','V','T','R','S'];
     case op of
       'C':menu:=1;
       'V':menu:=2;
       'T':menu:=3;
       'R':menu:=4;
       'S':menu:=5;
     end;
     borra(82,50,237,175);
end;

{[]========================================================================[]}
{                               Font                                         }
{[]========================================================================[]}
procedure loadfont;
Var
   H: Word;
   P: Pointer;
Begin
     P:=@Font;                          { Cambia el font al de 8.FNT }
     Datos.BuscaHandle('8.FNT', H);
     ChkForErrors;
     Datos.LeeArch(H, P, 0);
     ChkForErrors;
End;

{[]========================================================================[]}
{                              Presentaci¢n                                  }
{[]========================================================================[]}
Procedure Presentacion;
Var
   AuxPal: Paleta;
   H: Word;
   P: Pointer;
Begin
     FillChar(AuxPal, Sizeof(AuxPal), 0);
     RestorePaleta(AuxPal, 255);
     Datos.BuscaHandle('TITULO.CEL', H);
     ChkForErrors;
     Datos.LeeArch(H, Vid.Data, 0);
     ChkForErrors;
     Datos.BuscaHandle('PALETA.COL', H);
     ChkForErrors;
     P:=@AuxPal;
     Datos.LeeArch(H, P, 0);
     ChkForErrors;
     Delay(250);
     Fade_In(AuxPal, 12);
     Repeat Until Keypressed;
     While KeyPressed do ReadKey;
     FillChar(AuxPal, Sizeof(AuxPal), 0);
     Fade_Out(AuxPal, 20);
     FillChar(Vid.Data^, 64000, 0);
End;
{[]========================================================================[]}
{                               Principal                                    }
{[]========================================================================[]}
var
   op: byte;
begin
{$IFDEF Debuggeando}
  fillchar(presionada, sizeof(presionada), false);
{$ENDIF}

     fillchar(sprites, sizeof(sprites), 0);
     fondo:=NIL;
     menuscr:=NIL;
     Datos.Init(FDatos);
     ChkForErrors;
     lee_records;
     initgraphics;
     presentacion;
     loadfont;
     init_tablero;
     cargapaleta;
     loadcels;
     loadfondo;
     salir:=false;
     jugando:=false;
     repeat
           op:=menu;
           case op of
             1:begin
                    jugando:=false;
                    jugar;
               end;
             2:jugar;
             3:Begin
                    Jugando:=False;
                    Game_Over;
                    Ingresa_Record;
               End;
             4:Ver_Records(1);
             5:salir:=true;
           end;
           while keypressed do readkey;
     until salir;
     libera_mem;
     textmode(CO80);
end.
