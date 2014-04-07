{*******************************************************}
{                                                       }
{       Unidad LIBRERIA                                 }
{       Creada por Luis Parravicini, 08/04/1995.        }
{                                                       }
{   þ M ximo de 200 archivos.                           }
{   þ Los archivos no deben superar los 64K             }
{                                                       }
{*******************************************************}

Unit Libreria;

interface

Const
     Max = 200;
Type
    Arch = Record
      Nombre: Array [1..12] of Char;    { Nombre del archivo }
      MaxX, MaxY: Integer;              { Ancho y alto (si es un CEL) }
      Compress: Byte;                   { Tipo de compresi¢n: }
                                        {     0 sin comprimir }
                                        {     1 RLE           }
      OrigSize, Size: Word;             { Tama¤o original y comprimido }
      Pos: Longint;                     { Posici¢n en la librer¡a }
    End;

    Lib = Object
      Archs: Array [1..Max] of Arch;
      MaxArchs: Integer;
      FLib: File;
      Error: Byte;
      Constructor Init(S: String);
      Procedure BuscaHandle(S: String; var Handle: Word);
      Procedure LeeArch(Handle: Word; var P: Pointer; Asigna: Byte);
    End;

implementation

Uses MiscTool, Compacta;

Constructor Lib.Init(S: String);
{ Errores:                                                                     }
{           0  No hay error.                                                   }
{           2  Archivo no encontrado.                                          }
{         100  Error de lectura.                                               }
Var
   NumR: Word;
   Fin: Boolean;
Begin
     FillChar(Archs, Sizeof(Archs), 0);
     MaxArchs:=0;
     If Not Exist(S) then Error:=2
     else begin
       Assign(FLib, S);
       Reset(FLib, 1);
       Inc(MaxArchs);
       Fin:=False;
       While (MaxArchs <= Max) and Not Fin do begin
         BlockRead(FLib, Archs[MaxArchs], Sizeof(Archs[MaxArchs]), NumR);
         If (Sizeof(Archs[MaxArchs]) <> NumR) then begin
           Close(FLib);
           Error:=100;
           Exit
         End;
         Fin:=(Archs[MaxArchs].Nombre[1] = #0);
         Inc(MaxArchs);
       End;
       Dec(MaxArchs, 2);
       Close(FLib);
       Error:=0;
     End;
End;

Procedure Lib.BuscaHandle(S: String; var Handle: Word);
{ Errores:                                                                   }
{         0 No hay error.                                                    }
{         4 Archivo no encontrado.                                           }
Var
   I: Integer;
   S1: Array [1..12] of Char;
Begin
     FillChar(S1, 12, 0);
     Move(S[1], S1, Length(S));
     I:=1;
     While (I <= MaxArchs) and (Archs[I].Nombre <> S1) do Inc(I);
     Handle:=I;
     If (I > MaxArchs) then Error:=4
     else
       Error:=0;
End;

Procedure Lib.LeeArch(Handle: Word; var P: Pointer; Asigna: Byte);
{ Asigna:          0 No asigna memoria. Lee en P^.                           }
{         Otro valor Asigna memoria y lee en P^.                             }
{ Errores:                                                                   }
{           0 No hay error.                                                  }
{           2 Archivo no encontrado.                                         }
{           3 Handle inv lido.                                               }
{           8 No hay suficiente memoria.                                     }
{         100 Error de lectura.                                              }
Var
   F: File;
   NumR: Word;
   P1: Pointer;
Begin
     Error:=0;
     {$I-} Reset(FLib, 1); {$I+}
     If (IOResult <> 0) then Error:=2
     else
       If (Handle > MaxArchs) then Error:=3
       else
           If (Asigna <> 0) and (MaxAvail < Archs[Handle].OrigSize) then
             Error:=8
           else begin
             Reset(FLib, 1);
             If (Asigna <> 0) then GetMem(P, Archs[Handle].OrigSize);
             Seek(FLib, Archs[Handle].Pos);
             If (Archs[Handle].Compress = 1) then begin
               If (MaxAvail < Archs[Handle].Size) then Error:=8
               else begin
                 GetMem(P1, Archs[Handle].Size);
                 BlockRead(FLib, P1^, Archs[Handle].Size, NumR);
               End;
             end else
               BlockRead(FLib, P^, Archs[Handle].Size, NumR);
             Close(FLib);
             If (Archs[Handle].Size <> NumR) then begin
               FreeMem(P, Archs[Handle].OrigSize);
               Error:=100
             end else
               If (Archs[Handle].Compress = 1) then begin
                 UnRLE(P1, P, Archs[Handle].Size);
                 FreeMem(P1, Archs[Handle].Size);
               End;
           End;
End;

End.