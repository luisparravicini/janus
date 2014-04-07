{*******************************************************}
{                                                       }
{       Unidad COLORES                                  }
{       Creada por Luis Parravicini, 24/07/1994.        }
{                                                       }
{                                                       }
{*******************************************************}

unit colores;

interface
{                                                                              }
{   guardar paleta                                                             }
{         3C7   mandarle el nro. de color                                      }
{         3C9   devuelve el RGB del color (leer el port tres veces)            }
{                                                                              }
{   cambiar paleta                                                             }
{         3C8   mandarle el nro. de color                                      }
{         3C9   mandarle el RGB del color (escribir al port tres veces)        }
{                                                                              }
const
     min = 0;
     max = 255;
type
    RGB = record
      red, green, blue: byte
    end;

    paleta = array [min..max] of RGB;

procedure GetRGBColor(Color: Word; var ColorRGB: RGB);
procedure PutRGBColor(Color: Word; var ColorRGB: RGB);
procedure GetPaleta(var Pal: Paleta);
procedure RestorePaleta(Pal: Paleta; max: byte);
procedure Fade_In(Pal:Paleta; Espera: Byte);
procedure Fade_Out(Pal:Paleta; Espera: Byte);

implementation

uses crt;
var
   i:integer;

procedure GetRGBColor(Color: Word; var ColorRGB: RGB);
begin
     port[$3C7]:=Color;
     ColorRGB.Red:=port[$3C9];
     ColorRGB.Green:=port[$3C9];
     ColorRGB.Blue:=port[$3C9];
end;

procedure PutRGBColor(Color: Word; var ColorRGB: RGB);
begin
     port[$3C8]:=Color;
     port[$3C9]:=ColorRGB.Red;
     port[$3C9]:=ColorRGB.Green;
     port[$3C9]:=ColorRGB.Blue;
end;

procedure GetPaleta(var Pal: Paleta);
begin
     for i:=min to max do GetRGBColor(i, Pal[i]);
end;

procedure RestorePaleta(Pal: Paleta; max: byte);
begin
     for i:=min to max do PutRGBColor(i, Pal[i]);
end;

procedure Fade_In(Pal:Paleta; Espera: Byte);
var
   color:rgb;
   t,j:integer;
begin
     j:=0;
     while j<=63 do begin
       for t:=min to max do begin
         getrgbcolor(t, color);
         port[$3C8]:=t;
         if (color.red<>Pal[t].red) then port[$3C9]:=j
           else port[$3C9]:=color.red;
         if (color.green<>Pal[t].green) then port[$3C9]:=j
           else port[$3C9]:=color.green;
         if (color.blue<>Pal[t].blue) then port[$3C9]:=j
           else port[$3C9]:=color.blue;
         if t mod espera=0 then delay(1);
       end;
       inc(j);
     end;
end;

procedure Fade_Out(Pal:Paleta; Espera: Byte);
var
   color: rgb;
   t,j: byte;
begin
     j:=63;
     while j>0 do begin
       for t:=min to max do begin
         getrgbcolor(t, color);
         port[$3C8]:=t;
         if (color.red<>Pal[t].Red) then port[$3C9]:=color.red-1
           else port[$3C9]:=Pal[t].Red;
         if (color.green<>Pal[t].Green) then port[$3C9]:=color.green-1
           else port[$3C9]:=Pal[t].Green;
         if (color.blue<>Pal[t].Blue) then port[$3C9]:=color.blue-1
           else port[$3C9]:=Pal[t].Blue;
         if t mod espera=0 then delay(1);
       end;
       dec(j);
     end;
end;


end.
