library Game;

{$Mode ObjFPC}

uses Classes;

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..255999] of byte;

const
  bufferSize = 256000; { 64000 * 4 }
  vgaWidth = 320;
  vgaHeight = 200;

var
  surface: PByteArray;
  bufferInitialised: boolean;

procedure initBuffer; cdecl;
begin
  if not bufferInitialised then begin
    getmem(surface, bufferSize);
    bufferInitialised := true
  end;
end;

function getSurface: pointer; cdecl;
begin
  getSurface := surface
end;

procedure cls(const colour: longword); cdecl;
var
  a, r, g, b: byte;
  x, y: word;
begin
  if not bufferInitialised then exit;

  a := colour shr 24 and $FF;
  r := colour shr 16 and $FF;
  g := colour shr 8 and $FF;
  b := colour and $FF;

  for y:=0 to vgaHeight - 1 do
  for x:=0 to vgaWidth - 1 do begin
    surface^[y * vgaWidth * 4 + x * 4] := a;
    surface^[y * vgaWidth * 4 + x * 4 + 1] := r;
    surface^[y * vgaWidth * 4 + x * 4 + 2] := g;
    surface^[y * vgaWidth * 4 + x * 4 + 3] := b;
  end;
end;

exports
  initBuffer,
  getSurface,
  cls;

begin
{ Starting point is intentionally left empty }
end.

