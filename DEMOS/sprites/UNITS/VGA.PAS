{
  VGA unit
  Part of POSIT-92 Framework
}

unit VGA;

{$Mode TP}
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
procedure clsBlend(const colour: longword);
procedure flush; external 'env' name 'flush';

procedure unsafePset(const x, y: integer; const colour: longword); public name 'unsafePset';
procedure pset(const x, y: integer; const colour: longword); public name 'pset';

procedure unsafePsetBlend(const x, y: integer; const colour: longword); public name 'unsafePsetBlend';
procedure psetBlend(const x, y: integer; const colour: longword); public name 'psetBlend';

implementation

uses Logger;

var
  bufferInitialised: boolean;

procedure initBuffer;
begin
  { writeLog('Attempting to call initBuffer'); }

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

{ Gets the colour of a pixel }
function pget(const x, y: integer): longword;
var
  offset: longword;
begin
  if (x >= vgaWidth) or (x < 0) or (y >= vgaHeight) or (y < 0) then begin
    pget := 0;
    exit
  end;

  offset := (y * vgaWidth + x) * 4;

  pget := (surface[offset + 3] shl 24) or
    (surface[offset] shl 16) or
    (surface[offset + 1] shl 8) or
    surface[offset + 2]
end;

procedure unsafePsetBlend(const x, y: integer; const colour: longword);
var
  srcA, srcR, srcG, srcB: byte;
  destA, destR, destG, destB: byte;
  outA, outR, outG, outB: byte;
  offset: longword;
  { inverted alpha }
  alpha, invAlpha: single;
begin
  srcA := colour shr 24 and $FF;

  if srcA = 0 then exit;

  srcR := colour shr 16 and $FF;
  srcG := colour shr 8 and $FF;
  srcB := colour and $FF;
  
  offset := (x + y * vgaWidth) * 4;

  { Handle opaque pixel }
  if srcA = 255 then begin
    surface[offset] := srcR;
    surface[offset + 1] := srcG;
    surface[offset + 2] := srcB;
    surface[offset + 3] := srcA;
    exit
  end;

  destR := surface[offset];
  destG := surface[offset + 1];
  destB := surface[offset + 2];
  destA := surface[offset + 3];
  
  { Handle alpha blending }
  alpha := srcA / 255.0;
  invAlpha := 1.0 - alpha;

  outR := round(srcR * alpha + destR * invAlpha);
  outG := round(srcG * alpha + destG * invAlpha);
  outB := round(srcB * alpha + destB * invAlpha);
  outA := srcA + round(destA * invAlpha);

  surface[offset] := outR;
  surface[offset + 1] := outG;
  surface[offset + 2] := outB;
  surface[offset + 3] := outA;
end;

procedure psetBlend(const x, y: integer; const colour: longword);
begin
  if (x >= vgaWidth) or (x < 0) or (y >= vgaHeight) or (y < 0) then exit;

  unsafePsetBlend(x, y, colour)
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

procedure clsBlend(const colour: longword);
var
  a, b: integer;
begin
  if not bufferInitialised then exit;
  
  for b:=0 to vgaHeight - 1 do
  for a:=0 to vgaWidth - 1 do
    unsafePsetBlend(a, b, colour);
end;


end.