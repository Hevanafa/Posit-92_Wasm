unit VGA;

{$Mode ObjFPC}

interface

const
  bufferSize = 256000; { 64000 * 4 }

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..bufferSize - 1] of byte;

const
  vgaWidth = 320;
  vgaHeight = 200;

procedure initBuffer; public name 'initBuffer';
function getSurface: pointer; public name 'getSurface';
{ Colour format: $AARRGGBB }
procedure cls(const colour: longword); public name 'cls';


implementation

var
  surface: TByteArray;
  bufferInitialised: boolean;

procedure initBuffer;
begin
  if not bufferInitialised then begin
    { This throws
      "Uncaught (in promise) RuntimeError: null function or function signature mismatch"
      for some reason }
    { getmem(surface, bufferSize); }
    bufferInitialised := true
  end;
end;

function getSurface: pointer;
begin
  getSurface := @surface
end;

procedure cls(const colour: longword);
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
    surface[y * vgaWidth * 4 + x * 4] := r;
    surface[y * vgaWidth * 4 + x * 4 + 1] := g;
    surface[y * vgaWidth * 4 + x * 4 + 2] := b;
    surface[y * vgaWidth * 4 + x * 4 + 3] := a;
  end;
end;


end.