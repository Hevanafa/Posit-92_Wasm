{
  VGA unit - Part of Posit-92 game engine
  Hevanafa
}

unit VGA;

{$Mode ObjFPC}
{$H+}{$J-}
{$R-}
{$Q-}

{$Notes OFF}

interface

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..0] of byte;

{$ifdef WASM}
procedure vgaFlush; external 'env' name 'vgaFlush';
{$endif}

function vgaWidth: smallint;
function vgaHeight: smallint;

{ Ref: https://www.freepascal.org/docs-html/ref/refse22.html }
procedure initVideoMem(const width, height: smallint; const startAddr: PByteArray); public name 'initVideoMem';
function getSurfacePtr: PByteArray; public name 'getSurfacePtr';

{ Colour format: $AARRGGBB }
procedure cls(const colour: longword);
procedure clsBlend(const colour: longword);

function unsafePget(const x, y: smallint): longword;
function pget(const x, y: smallint): longword;

procedure legacyUnsafePset(const x, y: smallint; const colour: longword);
procedure unsafePset(const x, y: smallint; const colour: longword);
procedure pset(const x, y: smallint; const colour: longword);

procedure unsafePsetBlend(const x, y: smallint; const colour: longword);
procedure psetBlend(const x, y: smallint; const colour: longword);

function clipX1: smallint;
function clipY1: smallint;
function clipX2: smallint;
function clipY2: smallint;

procedure setClip(x1, y1, x2, y2: smallint);
procedure resetClip;


implementation

{$ifdef WASM}
uses
  Logger,
  WasmHeap;
{$endif}
{$ifdef Windows}
uses
  Logger;
{$endif}

var
  _vgaWidth, _vgaHeight: smallint;
  bufferSize: longword;
  surface: PByteArray;

  { inclusive clipping bounds }
  _clipX1, _clipY1, _clipX2, _clipY2: smallint;

function vgaWidth: smallint;
begin
  vgaWidth := _vgaWidth
end;

function vgaHeight: smallint;
begin
  vgaHeight := _vgaHeight
end;

procedure initVideoMem(const width, height: smallint; const startAddr: PByteArray);
begin
  { writeLog('Attempting to call initVideoMem'); }
  _vgaWidth := width;
  _vgaHeight := height;
  bufferSize := _vgaWidth * _vgaHeight * 4;

  resetClip;

  surface := startAddr;
  fillchar(surface^, bufferSize, 0);
end;

function getSurfacePtr: PByteArray;
begin
  getSurfacePtr := surface
end;

function unsafePget(const x, y: smallint): longword;
var
  offset: longword;
begin
  offset := (x + y * _vgaWidth) * 4;

  { RGBA to ARGB }
  unsafePget := surface^[offset + 3] shl 24
    or surface^[offset] shl 16
    or surface^[offset + 1] shl 8
    or surface^[offset + 2]
end;

{ Gets the colour of a pixel }
function pget(const x, y: smallint): longword;
begin
  if (x >= vgaWidth) or (x < 0) or (y >= vgaHeight) or (y < 0) then begin
    pget := 0;
    exit
  end;

  pget := unsafePget(x, y)
end;

procedure legacyUnsafePset(const x, y: smallint; const colour: longword);
var
  offset: longword;
begin
  offset := (y * vgaWidth + x) * 4;

  { ARGB to RGBA }
  surface^[offset] := (colour shr 16) and $FF;
  surface^[offset + 1] := (colour shr 8) and $FF;
  surface^[offset + 2] := colour and $FF;
  surface^[offset + 3] := (colour shr 24) and $FF;
end;

procedure unsafePset(const x, y: smallint; const colour: longword);
begin
  { ARGB to RGBA }
  PLongWord(@surface^[(y * vgaWidth + x) * 4])^ :=
    ((colour and $00FF0000) shr 16)
    or ((colour and $0000FF00))
    or ((colour and $000000FF) shl 16)
    or ((colour and $FF000000))
end;

{ colour: AARRGGBB }
procedure pset(const x, y: smallint; const colour: longword);
begin
  if (x > _clipX2) or (x < _clipX1) or (y > _clipY2) or (y < _clipX1) then
    exit;

  unsafePset(x, y, colour)
end;


procedure legacyUnsafePsetBlend(const x, y: smallint; const colour: longword);
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

procedure unsafePsetBlend(const x, y: smallint; const colour: longword);
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

procedure psetBlend(const x, y: smallint; const colour: longword);
begin
  if (x > _clipX2) or (x < _clipX1) or (y > _clipY2) or (y < _clipY1) then exit;

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
  a, b: word;
begin
  for b:=0 to vgaHeight - 1 do
  for a:=0 to vgaWidth - 1 do
    unsafePsetBlend(a, b, colour);
end;

function clipX1: smallint;
begin
  clipX1 := _clipX1
end;

function clipY1: smallint;
begin
  clipY1 := _clipY1
end;

function clipX2: smallint;
begin
  clipX2 := _clipX2
end;

function clipY2: smallint;
begin
  clipY2 := _clipY2
end;

procedure setClip(x1, y1, x2, y2: smallint);
var
  temp: smallint;
begin
  if x1 > x2 then begin
    temp := x1;  x1 := x2;  x2 := temp
  end;
  if y1 > y2 then begin
    temp := y1;  y1 := y2;  y2 := temp
  end;

  if x1 < 0 then x1 := 0;
  if x2 >= _vgaWidth then x2 := _vgaWidth - 1;
  if y1 < 0 then y1 := 0;
  if y2 >= _vgaHeight then y2 := _vgaHeight - 1;

  _clipX1 := x1;  _clipY1 := y1;
  _clipX2 := x2;  _clipY2 := y2;
end;

procedure resetClip;
begin
  _clipX1 := 0;
  _clipY1 := 0;
  _clipX2 := _vgaWidth - 1;
  _clipY2 := _vgaHeight - 1;
end;

end.
