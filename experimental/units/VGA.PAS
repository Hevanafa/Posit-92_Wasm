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
procedure VgaUpload; external 'env' name 'VgaUpload';
procedure VgaPresent; external 'env' name 'VgaPresent';
{$endif}

function VgaWidth: smallint;
function VgaHeight: smallint;

{ Ref: https://www.freepascal.org/docs-html/ref/refse22.html }
procedure InitVideoMem(const width, height: smallint; const startAddr: PByteArray); public name 'InitVideoMem';
function GetSurfacePtr: PByteArray; public name 'GetSurfacePtr';

{ colour format: $AARRGGBB like in QB64 PE }
procedure Cls(const colour: longword);
{ colour format: $AARRGGBB }
procedure ClsBlend(const colour: longword);

function UnsafePget(const x, y: smallint): longword;
function Pget(const x, y: smallint): longword;

procedure LegacyUnsafePset(const x, y: smallint; const colour: longword);
procedure UnsafePset(const x, y: smallint; const colour: longword);
procedure Pset(const x, y: smallint; const colour: longword);

procedure UnsafePsetBlend(const x, y: smallint; const colour: longword);
procedure PsetBlend(const x, y: smallint; const colour: longword);

function ClipX1: smallint;
function ClipY1: smallint;
function ClipX2: smallint;
function ClipY2: smallint;

procedure SetClip(x1, y1, x2, y2: smallint);
procedure ResetClip;


implementation

{$ifdef WASM}
uses
  P92Logger,
  WasmHeap;
{$endif}
{$ifdef Windows}
uses
  Logger;
{$endif}

var
  _vgaWidth, _vgaHeight: smallint;
  bufferSize: longword;
  activeSurface: PByteArray;

  { inclusive clipping bounds }
  _clipX1, _clipY1, _clipX2, _clipY2: smallint;

function VgaWidth: smallint;
begin
  VgaWidth := _vgaWidth
end;

function VgaHeight: smallint;
begin
  VgaHeight := _vgaHeight
end;

procedure InitVideoMem(const width, height: smallint; const startAddr: PByteArray);
begin
  { WriteLog('Attempting to call initVideoMem'); }
  _vgaWidth := width;
  _vgaHeight := height;
  bufferSize := _vgaWidth * _vgaHeight * 4;

  ResetClip;

  activeSurface := startAddr;
  fillchar(activeSurface^, bufferSize, 0);
end;

function GetSurfacePtr: PByteArray;
begin
  GetSurfacePtr := activeSurface
end;

function UnsafePget(const x, y: smallint): longword;
var
  offset: longword;
begin
  offset := (x + y * _vgaWidth) * 4;

  { RGBA to ARGB }
  UnsafePget := activeSurface^[offset + 3] shl 24
    or activeSurface^[offset] shl 16
    or activeSurface^[offset + 1] shl 8
    or activeSurface^[offset + 2]
end;

{ Gets the colour of a pixel }
function Pget(const x, y: smallint): longword;
begin
  if (x >= VgaWidth) or (x < 0) or (y >= VgaHeight) or (y < 0) then begin
    Pget := 0;
    exit
  end;

  Pget := UnsafePget(x, y)
end;

procedure LegacyUnsafePset(const x, y: smallint; const colour: longword);
var
  offset: longword;
begin
  offset := (y * VgaWidth + x) * 4;

  { ARGB to RGBA }
  activeSurface^[offset] := (colour shr 16) and $FF;
  activeSurface^[offset + 1] := (colour shr 8) and $FF;
  activeSurface^[offset + 2] := colour and $FF;
  activeSurface^[offset + 3] := (colour shr 24) and $FF;
end;

procedure UnsafePset(const x, y: smallint; const colour: longword);
begin
  { ARGB to RGBA }
  PLongWord(@activeSurface^[(y * VgaWidth + x) * 4])^ :=
    ((colour and $00FF0000) shr 16)
    or ((colour and $0000FF00))
    or ((colour and $000000FF) shl 16)
    or ((colour and $FF000000))
end;

{ colour: AARRGGBB }
procedure Pset(const x, y: smallint; const colour: longword);
begin
  if (x > _clipX2) or (x < _clipX1) or (y > _clipY2) or (y < _clipX1) then
    exit;

  UnsafePset(x, y, colour)
end;


procedure LegacyUnsafePsetBlend(const x, y: smallint; const colour: longword);
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
  
  offset := (x + y * VgaWidth) * 4;

  { Handle opaque pixel }
  if srcA = 255 then begin
    activeSurface^[offset] := srcR;
    activeSurface^[offset + 1] := srcG;
    activeSurface^[offset + 2] := srcB;
    activeSurface^[offset + 3] := srcA;
    exit
  end;

  destR := activeSurface^[offset];
  destG := activeSurface^[offset + 1];
  destB := activeSurface^[offset + 2];
  destA := activeSurface^[offset + 3];
  
  { Handle alpha blending }
  alpha := srcA / 255.0;
  invAlpha := 1.0 - alpha;

  outR := round(srcR * alpha + destR * invAlpha);
  outG := round(srcG * alpha + destG * invAlpha);
  outB := round(srcB * alpha + destB * invAlpha);
  outA := srcA + round(destA * invAlpha);

  activeSurface^[offset] := outR;
  activeSurface^[offset + 1] := outG;
  activeSurface^[offset + 2] := outB;
  activeSurface^[offset + 3] := outA;
end;

procedure UnsafePsetBlend(const x, y: smallint; const colour: longword);
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
  
  offset := (x + y * VgaWidth) * 4;

  { Handle opaque pixel }
  if srcA = 255 then begin
    UnsafePset(x, y, colour);
    exit
  end;

  destR := activeSurface^[offset];
  destG := activeSurface^[offset + 1];
  destB := activeSurface^[offset + 2];
  destA := activeSurface^[offset + 3];
  
  { Handle alpha blending }
  alpha := srcA / 255.0;
  invAlpha := 1.0 - alpha;

  PLongWord(@activeSurface^[offset])^ :=
    (round(srcR * alpha + destR * invAlpha))
    or (round(srcG * alpha + destG * invAlpha) shl 8)
    or (round(srcB * alpha + destB * invAlpha) shl 16)
    or ((srcA + round(destA * invAlpha)) shl 24)
end;

procedure PsetBlend(const x, y: smallint; const colour: longword);
begin
  if (x > _clipX2) or (x < _clipX1) or (y > _clipY2) or (y < _clipY1) then exit;

  UnsafePsetBlend(x, y, colour)
end;

procedure Cls(const colour: longword);
begin
  FillDWord(
    GetSurfacePtr^,
    VgaWidth * VgaHeight,
    { convert ARGB to RGBA + flip the byte order }
    SwapEndian((colour and $FFFFFF shl 8) or (colour and $FF000000 shr 24)))
end;

procedure ClsBlend(const colour: longword);
var
  a, b: word;
begin
  for b:=0 to VgaHeight - 1 do
  for a:=0 to VgaWidth - 1 do
    UnsafePsetBlend(a, b, colour);
end;

function ClipX1: smallint;
begin
  ClipX1 := _clipX1
end;

function ClipY1: smallint;
begin
  ClipY1 := _clipY1
end;

function ClipX2: smallint;
begin
  ClipX2 := _clipX2
end;

function ClipY2: smallint;
begin
  ClipY2 := _clipY2
end;

procedure SetClip(x1, y1, x2, y2: smallint);
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

procedure ResetClip;
begin
  _clipX1 := 0;
  _clipY1 := 0;
  _clipX2 := _vgaWidth - 1;
  _clipY2 := _vgaHeight - 1;
end;

end.
