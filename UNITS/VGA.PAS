unit VGA;

{$B-}  { Enable boolean short-circuiting }

interface

const
  bufferSize = 256000; { 64000 * 4 }

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..bufferSize - 1] of byte;

const
  vgaWidth = 320;
  vgaHeight = 200;

var
  surface: TByteArray;

{ Ref: https://www.freepascal.org/docs-html/ref/refse22.html }
procedure initBuffer; public name 'initBuffer';
function getSurface: pointer; public name 'getSurface';

{ Colour format: $AARRGGBB }
procedure cls(const colour: longword); public name 'cls';

procedure unsafePset(const x, y: integer; const colour: longword);
procedure pset(const x, y: integer; const colour: longword);

{ flush is available in JS code }

implementation

uses Logger;

var
  bufferInitialised: boolean;

procedure initBuffer;
begin
  writeLog('Attempting to call initBuffer');

  if not bufferInitialised then begin
    { This throws
      "Uncaught (in promise) RuntimeError: null function or function signature mismatch"
      for some reason }
    { Issue: https://en.delphipraxis.net/topic/7122-free-pascal-web-assembly-objects/ }
    { getmem(surface, bufferSize); }
    bufferInitialised := true
  end;
end;

function getSurface: pointer;
begin
  getSurface := @surface
end;

procedure unsafePset(const x, y: integer; const colour: longword);
var
  a, r, g, b: byte;
  offset: longword;
begin
  a := colour shr 24 and $FF;
  r := colour shr 16 and $FF;
  g := colour shr 8 and $FF;
  b := colour and $FF;

  offset := (y * vgaWidth + x) * 4;
  surface[offset] := r;
  surface[offset + 1] := g;
  surface[offset + 2] := b;
  surface[offset + 3] := a;
end;

{ colour: AARRGGBB }
procedure pset(const x, y: integer; const colour: longword);
begin
  if (x >= vgaWidth) or (x < 0) or (y >= vgaHeight) or (y < 0) then exit;
  unsafePset(x, y, colour)
end;

procedure cls(const colour: longword);
var
  x, y: word;
begin
  if not bufferInitialised then exit;

  for y:=0 to vgaHeight - 1 do
    for x:=0 to vgaWidth - 1 do
      unsafePset(x, y, colour);
end;


end.