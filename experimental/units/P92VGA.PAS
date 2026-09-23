{
  VGA unit
  Part of Posit-92 game engine
  By Hevanafa

  The default colour value to pass around is in $AARRGGBB format

  Internally, the backbuffer consists of a series of this array:
  [R, G, B, A]
}

unit P92VGA;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }
{$R-}
{$Q-}

{$Inline ON}
{Notes OFF}

interface

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..0] of byte;

{$ifdef P92_WASM}
procedure VGAUpload; external 'env' name 'VGAUpload';
procedure VGAPresent; external 'env' name 'VGAPresent';
{$endif}

{$ifdef P92_SDL2}
{ Uploads the pixel data to the GPU }
procedure VgaUpload;
procedure VgaPresent;
{$endif}

function VGAWidth: smallint;
function VGAHeight: smallint;

{ This is called by InitWasmMemory (JS side)
  Ref: https://www.freepascal.org/docs-html/ref/refse22.html }
procedure InitVideoMem(const width, height: smallint; const startAddr: PByteArray); public name 'InitVideoMem';

function BorrowSurfacePtr: PByteArray; public name 'GetSurfacePtr';

{ colour format: $AARRGGBB like in QB64 PE }
procedure Cls(const colour: longword);
{ colour format: $AARRGGBB }
procedure ClsBlend(const colour: longword);

function ARGBtoRGBA(const colour: longword): longword;
function ARGBtoABGR(const colour: longword): longword;

{ Returns colour in ABGR }
function UnsafePGet(const x, y: smallint): longword;
procedure UnsafePSet(const x, y: smallint; const ABGR: longword);
procedure UnsafePSetBlend(const x, y: smallint; const ABGR: longword);

{ Gets the colour of a pixel from the backbuffer
  Returns colour in ARGB }
function PGet(const x, y: smallint): longword;
procedure PSet(const x, y: smallint; const colour: longword);
procedure PSetBlend(const x, y: smallint; const colour: longword);

function ClipX1: smallint;
function ClipY1: smallint;
function ClipX2: smallint;
function ClipY2: smallint;

procedure SetClip(x1, y1, x2, y2: smallint);
procedure ResetClip;


implementation

{$ifdef P92_WASM}
uses
  P92Logger,
  P92WasmHeap;
{$endif}
{$ifdef P92_SDL2}
uses
  SDL2, P92Logger, P92CoreSDL2;
{$endif}

var
  _vgaWidth, _vgaHeight: smallint;
  bufferSize: longword;
  activeSurface: PByteArray;

  { inclusive clipping bounds }
  _clipX1, _clipY1, _clipX2, _clipY2: smallint;

function VGAWidth: smallint;
begin
  VGAWidth := _vgaWidth
end;

function VGAHeight: smallint;
begin
  VGAHeight := _vgaHeight
end;

{$ifdef P92_SDL2}
procedure VgaUpload;
begin
  { SDL_SetRenderDrawColor(renderer, $ed, $95, $64, $ff);
  SDL_RenderClear(renderer); }

  SDL_SetTextureBlendMode(vgaTexture, SDL_BLENDMODE_BLEND);
  SDL_UpdateTexture(vgaTexture, nil, getSurfacePtr, vgaWidth * 4); { pitch = width * 4 bytes }
  SDL_RenderCopy(renderer, vgaTexture, nil, nil)
end;

procedure VgaPresent;
begin
  SDL_RenderPresent(renderer)
end;
{$endif}

procedure InitVideoMem(const width, height: smallint; const startAddr: PByteArray);
begin
  _vgaWidth := width;
  _vgaHeight := height;
  bufferSize := _vgaWidth * _vgaHeight * 4;

  ResetClip;

  activeSurface := startAddr;
  fillchar(activeSurface^, bufferSize, 0);
end;

function BorrowSurfacePtr: PByteArray;
begin
  BorrowSurfacePtr := activeSurface
end;

function ARGBtoRGBA(const colour: longword): longword; inline;
begin
  ARGBtoRGBA := (
       ((colour and $00FFFFFF) shl 8)
    or ((colour and $FF000000) shr 24))
end;

function ARGBtoABGR(const colour: longword): longword; inline;
begin
  ARGBtoABGR :=
    (colour and $FF00FF00)
    or ((colour and $00FF0000) shr 16)
    or ((colour and $000000FF) shl 16)
end;

function ABGRtoARGB(const colour: longword): longword; inline;
begin
  ABGRtoARGB := ARGBtoABGR(colour)
end;

function UnsafePGet(const x, y: smallint): longword; inline;
var
  offset: longword;
begin
  offset := (x + y * _vgaWidth) * 4;
  UnsafePGet := PLongWord(@activeSurface^[offset])^
end;

function PGet(const x, y: smallint): longword;
begin
  if (x >= VGAWidth) or (x < 0) or (y >= VGAHeight) or (y < 0) then begin
    PGet := 0;
    exit
  end;

  PGet := ABGRtoARGB(UnsafePGet(x, y))
end;

procedure UnsafePSet(const x, y: smallint; const ABGR: longword);
begin
  PLongWord(@activeSurface^[(y * VGAWidth + x) * 4])^ := ABGR
end;

procedure PSet(const x, y: smallint; const colour: longword);
begin
  if (x > _clipX2) or (x < _clipX1) or (y > _clipY2) or (y < _clipX1) then
    exit;

  UnsafePSet(x, y, ARGBtoABGR(colour))
end;


procedure UnsafePSetBlend(const x, y: smallint; const ABGR: longword); inline;
var
  srcA, srcR, srcG, srcB: byte;
  destA, destR, destG, destB: byte;
  offset: longword;
  { inverted alpha }
  alpha, invAlpha: single;
begin
  srcA := ABGR shr 24 and $FF;

  if srcA = 0 then exit;

  srcR := ABGR and $FF;
  srcG := ABGR shr 8 and $FF;
  srcB := ABGR shr 16 and $FF;
  
  offset := (x + y * VGAWidth) * 4;

  { Handle opaque pixel }
  if srcA = 255 then begin
    UnsafePSet(x, y, ABGR);
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
    ((srcA + round(destA * invAlpha)) shl 24)
    or (round(srcB * alpha + destB * invAlpha) shl 16)
    or (round(srcG * alpha + destG * invAlpha) shl 8)
    or (round(srcR * alpha + destR * invAlpha))
end;

procedure PSetBlend(const x, y: smallint; const colour: longword);
begin
  if (x > _clipX2) or (x < _clipX1) or (y > _clipY2) or (y < _clipY1) then exit;

  UnsafePSetBlend(x, y, ARGBtoABGR(colour))
end;

procedure Cls(const colour: longword);
begin
  FillDWord(
    BorrowSurfacePtr^,
    VgaWidth * VgaHeight,
    ARGBtoABGR(colour))
end;

procedure ClsBlend(const colour: longword);
var
  a, b: word;
  ABGR: longword;
begin
  ABGR := ARGBtoABGR(colour);

  for b:=0 to VGAHeight - 1 do
    for a:=0 to VGAWidth - 1 do
      UnsafePSetBlend(a, b, ABGR);
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
