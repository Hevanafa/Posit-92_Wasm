{
  VGA unit - Part of Posit-92 game engine
  Hevanafa
}

unit VGA;

{$Mode TP}
{$Notes OFF}
{$B-}  { Enable boolean short-circuiting }

interface

{$ifdef WASM}
procedure vgaFlush; external 'env' name 'vgaFlush';
{$endif}

{ Ref: https://www.freepascal.org/docs-html/ref/refse22.html }
procedure initVideoMem(const width, height: smallint; const startAddr: PByte); public name 'initVideoMem';
function getSurfacePtr: PByte; public name 'getSurfacePtr';

{ Colour format: $AARRGGBB }
procedure cls(const colour: longword);
procedure clsBlend(const colour: longword);

function unsafePget(const x, y: integer): longword;
function pget(const x, y: integer): longword;

procedure unsafePset(const x, y: integer; const colour: longword);
procedure pset(const x, y: integer; const colour: longword);

procedure unsafePsetBlend(const x, y: integer; const colour: longword);
procedure psetBlend(const x, y: integer; const colour: longword);


implementation

{$ifdef WASM}
uses
  Logger,
  WasmHeap;
{$endif}
{$ifdef WIN64}
uses
  Logger;
{$endif}

var
  vgaWidth, vgaHeight: smallint;
  bufferSize: longword;
  surface: PByte;

procedure initVideoMem(const width, height: smallint; const startAddr: PByte);
begin
  { writeLog('Attempting to call initVideoMem'); }
  vgaWidth := width;
  vgaHeight := height;
  bufferSize := vgaWidth * vgaHeight * 4;

  surface := startAddr;
  fillchar(surface^, bufferSize, 0);
end;

function getSurfacePtr: PByte;
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

{ Gets the colour of a pixel }
function pget(const x, y: integer): longword;
begin
  if (x >= vgaWidth) or (x < 0) or (y >= vgaHeight) or (y < 0) then begin
    pget := 0;
    exit
  end;

  pget := unsafePget(x, y)
end;

procedure legacyUnsafePset(const x, y: integer; const colour: longword);
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

procedure unsafePset(const x, y: integer; const colour: longword);
begin
  { ARGB to RGBA }
  PLongWord(@surface^[(y * vgaWidth + x) * 4])^ :=
    ((colour and $00FF0000) shr 16)
    or ((colour and $0000FF00))
    or ((colour and $000000FF) shl 16)
    or ((colour and $FF000000))
end;

{ colour: AARRGGBB }
procedure pset(const x, y: integer; const colour: longword);
begin
  if (x >= vgaWidth) or (x < 0) or (y >= vgaHeight) or (y < 0) then exit;
  unsafePset(x, y, colour)
end;


procedure legacyUnsafePsetBlend(const x, y: integer; const colour: longword);
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

procedure unsafePsetBlend(const x, y: integer; const colour: longword);
var
  srcA, srcR, srcG, srcB: byte;
  destA, destR, destG, destB: byte;
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
    unsafePset(x, y, colour);
    exit
  end;

  destR := surface^[offset];
  destG := surface^[offset + 1];
  destB := surface^[offset + 2];
  destA := surface^[offset + 3];
  
  { Handle alpha blending }
  alpha := srcA / 255.0;
  invAlpha := 1.0 - alpha;

  PLongWord(@surface^[offset])^ :=
    (round(srcR * alpha + destR * invAlpha))
    or (round(srcG * alpha + destG * invAlpha) shl 8)
    or (round(srcB * alpha + destB * invAlpha) shl 16)
    or ((srcA + round(destA * invAlpha)) shl 24)
end;

procedure psetBlend(const x, y: integer; const colour: longword);
begin
  if (x >= vgaWidth) or (x < 0) or (y >= vgaHeight) or (y < 0) then exit;

  unsafePsetBlend(x, y, colour)
end;

procedure cls(const colour: longword);
var
  a, b: word;
begin
  for b:=0 to vgaHeight - 1 do
  for a:=0 to vgaWidth - 1 do
    unsafePset(a, b, colour);
end;

procedure clsBlend(const colour: longword);
var
  a, b: integer;
begin
  for b:=0 to vgaHeight - 1 do
  for a:=0 to vgaWidth - 1 do
    unsafePsetBlend(a, b, colour);
end;


end.