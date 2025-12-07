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

{$ifdef WASM}
procedure toggleFullscreen; external 'env' name 'toggleFullscreen';
procedure flush; external 'env' name 'flush';
{$endif}

{ Ref: https://www.freepascal.org/docs-html/ref/refse22.html }
procedure initBuffer;
function getSurfacePtr: PByteArray; public name 'getSurfacePtr';

{ Colour format: $AARRGGBB }
procedure cls(const colour: longword);
procedure clsBlend(const colour: longword);

function unsafePget(const x, y: integer): longword;

procedure unsafePset(const x, y: integer; const colour: longword);
procedure pset(const x, y: integer; const colour: longword);

procedure unsafePsetBlend(const x, y: integer; const colour: longword);
procedure psetBlend(const x, y: integer; const colour: longword);


implementation

uses
  Logger, WasmHeap;

var
  bufferInitialised: boolean;
  surface: PByteArray;

procedure initBuffer;
begin
  writeLog('Attempting to call initBuffer');

  if not bufferInitialised then begin
    surface := PByteArray(WasmGetMem(bufferSize));
    fillchar(surface^, bufferSize, 0);
    bufferInitialised := true
  end;
end;

function getSurfacePtr: PByteArray;
begin
  getSurfacePtr := surface
end;

function unsafePget(const x, y: integer): longword;
var
  offset: longword;
begin
  offset := (x + y * vgaWidth) * 4;

  { RGBA to ARGB }
  unsafePget := surface^[offset + 3] shl 24
    or surface^[offset] shl 16
    or surface^[offset + 1] shl 8
    or surface^[offset + 2]
end;

procedure unsafePset(const x, y: integer; const colour: longword);
var
  offset: longword;
begin
  offset := (y * vgaWidth + x) * 4;

  { ARGB to RGBA }
  surface^[offset] := colour shr 16 and $FF;
  surface^[offset + 1] := colour shr 8 and $FF;
  surface^[offset + 2] := colour and $FF;
  surface^[offset + 3] := colour shr 24 and $FF;
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

  pget := (surface^[offset + 3] shl 24) or
    (surface^[offset] shl 16) or
    (surface^[offset + 1] shl 8) or
    surface^[offset + 2]
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
    surface^[offset] := srcR;
    surface^[offset + 1] := srcG;
    surface^[offset + 2] := srcB;
    surface^[offset + 3] := srcA;
    exit
  end;

  destR := surface^[offset];
  destG := surface^[offset + 1];
  destB := surface^[offset + 2];
  destA := surface^[offset + 3];
  
  { Handle alpha blending }
  alpha := srcA / 255.0;
  invAlpha := 1.0 - alpha;

  outR := round(srcR * alpha + destR * invAlpha);
  outG := round(srcG * alpha + destG * invAlpha);
  outB := round(srcB * alpha + destB * invAlpha);
  outA := srcA + round(destA * invAlpha);

  surface^[offset] := outR;
  surface^[offset + 1] := outG;
  surface^[offset + 2] := outB;
  surface^[offset + 3] := outA;
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