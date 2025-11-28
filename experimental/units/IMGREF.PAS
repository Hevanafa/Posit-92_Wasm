{
  ImgRef unit
  Part of Posit-92 framework
  By Hevanafa, 28-11-2025

  Most of the procedures & functions here are based on Bitmap and SprFast units
}

unit ImgRef;

{$Mode TP}
{$B-}  { Enable boolean short-circuiting }
{$R-}  { Turn off range checks }
{$Q-}  { Turn off overflow checks }

interface

type
  PImageRef = ^TImageRef;
  TImageRef = record
    width: integer;
    height: integer;
    dataPtr: PByte;
  end;

const
  { SprFlips enum }
  SprFlipNone = 0;
  SprFlipHorizontal = 1;
  SprFlipVertical = 2;
  SprFlipBoth = SprFlipHorizontal or SprFlipVertical;

procedure registerImageRef(const imgHandle: longint; const dataPtr: PByte; const w, h: integer); public name 'registerImageRef';

function newImageRef(const width, height: integer): longint;
function copyImageRef(const imgHandle: longint): longint;

function isImageSet(const imgHandle: longint): boolean;
function getImageRefPtr(const imgHandle: longint): PImageRef;

function getImageWidth(const imgHandle: longint): word;
function getImageHeight(const imgHandle: longint): word;

function unsafeSprPget(const image: PImageRef; const x, y: integer): longword;
procedure unsafeSprPset(const image: PImageRef; const x, y: integer; const colour: longword);

{ Based on SprFast unit }
{ Rendering procedures }
{ spr with TImageRef }
procedure sprRef(const imgHandle: longint; const x, y: integer);

procedure sprRefRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);

procedure sprRefStretch(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);

procedure sprRefRegionStretch(
  const imgHandle: longint;
  const srcX, srcY, srcWidth, srcHeight: integer;
  const destX, destY, destWidth, destHeight: integer);

procedure sprRefRegionSolid(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const colour: longword);

{ Based on SprComp unit }
procedure sprAlpha(const imgHandle: longint; const x, y: integer; opacity: double);


implementation

uses Logger, Maths, Panic, VGA, Wasm;

const
  MaxImageRefs = 256;

var
  imageRefs: array[1..MaxImageRefs] of TImageRef;


function findEmptyImageRefSlot: integer;
var
  a: longint;
begin
  for a:=1 to high(imageRefs) do
    if not isImageSet(a) then begin
      findEmptyImageRefSlot := a;
      exit
    end;

  findEmptyImageRefSlot := -1
end;

procedure registerImageRef(const imgHandle: longint; const dataPtr: PByte; const w, h: integer);
var
  idx: integer;
begin
  idx := findEmptyImageRefSlot;

  if idx < 0 then panicHalt('Image ref pool is full!');

  imageRefs[imgHandle].width := w;
  imageRefs[imgHandle].height := h;
  imageRefs[imgHandle].dataPtr := dataPtr;
end;

function newImageRef(const width, height: integer): longint;
var
  slot: longint;
  dataPtr: PByte;
  byteSize: longword;
begin
  byteSize := width * height * 4;
  dataPtr := PByte(WasmGetMem(byteSize));

  fillchar(dataPtr^, byteSize, 0);

  slot := findEmptyImageRefSlot;
  if slot < 0 then panicHalt('Image ref pool is full!');

  imageRefs[slot].width := width;
  imageRefs[slot].height := height;
  imageRefs[slot].dataPtr := dataPtr;

  newImageRef := slot
end;

{ imgHandle: Source image handle }
function copyImageRef(const imgHandle: longint): longint;
var
  slot: longint;
  src, dest: PImageRef;
begin
  src := getImageRefPtr(imgHandle);
  slot := newImageRef(src^.width, src^.height);
  dest := getImageRefPtr(slot);

  move(src^.dataPtr^, dest^.dataPtr^, src^.width * src^.height * 4);
  copyImageRef := slot
end;

function isImageSet(const imgHandle: longint): boolean;
begin
  isImageSet := (imageRefs[imgHandle].width > 0) and (imageRefs[imgHandle].height > 0)
end;

function getImageRefPtr(const imgHandle: longint): PImageRef;
begin
  getImageRefPtr := @imageRefs[imgHandle]
end;

function getImageWidth(const imgHandle: longint): word;
var
  image: PImageRef;
begin
  getImageWidth := 0;
  if not isImageSet(imgHandle) then exit;

  image := getImageRefPtr(imgHandle);
  getImageWidth := image^.width
end;

function getImageHeight(const imgHandle: longint): word;
var
  image: PImageRef;
begin
  getImageHeight := 0;
  if not isImageSet(imgHandle) then exit;

  image := getImageRefPtr(imgHandle);
  getImageHeight := image^.height
end;


{ Assuming image isn't nil & the bounds are known }
function unsafeSprPget(const image: PImageRef; const x, y: integer): longword;
var
  offset: longword;
begin
  offset := (x + y * image^.width) * 4;

  unsafeSprPget :=
    (image^.dataPtr[offset + 3] shl 24)
    or (image^.dataPtr[offset] shl 16)
    or (image^.dataPtr[offset + 1] shl 8)
    or image^.dataPtr[offset + 2]
end;

procedure unsafeSprPset(const image: PImageRef; const x, y: integer; const colour: longword);
var
  offset: longword;
begin
  offset := (x + y * image^.width) * 4;

  { Order: RGBA }
  image^.dataPtr[offset] := colour shr 16 and $FF;
  image^.dataPtr[offset + 1] := colour shr 8 and $FF;
  image^.dataPtr[offset + 2] := colour and $FF;
  image^.dataPtr[offset + 3] := colour shr 24 and $FF;
end;


{ Render procedures }

procedure sprRef(const imgHandle: longint; const x, y: integer);
var
  image: PImageRef;
  px, py: integer;
  offset: longword;
  data: PByte;
  a: byte;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImageRefPtr(imgHandle);
  data := PByte(image^.dataPtr);

  for py:=0 to image^.height - 1 do
  for px:=0 to image^.width - 1 do begin
    if (x + px >= vgaWidth) or (x + px < 0)
      or (y + py >= vgaHeight) or (y + py < 0) then continue;

    { offset to ImageData buffer }
    offset := (px + py * image^.width) * 4;
    a := data[offset + 3];
    if a < 255 then continue;

    colour := unsafeSprPget(image, px, py);
    unsafePset(x + px, y + py, colour)
  end;
end;

procedure sprRefRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);
var
  image: PImageRef;
  a, b: integer;
  sx, sy: integer;
  srcPos: longint;
  alpha: byte;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImageRefPtr(imgHandle);

  for b:=0 to srcH - 1 do
  for a:=0 to srcW - 1 do begin
    if (destX + a >= vgaWidth) or (destX + a < 0)
      or (destY + b >= vgaHeight) or (destY + b < 0) then continue;

    sx := srcX + a;
    sy := srcY + b;
    srcPos := (sx + sy * image^.width) * 4;

    alpha := image^.dataPtr[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, sx, sy);
    unsafePset(destX + a, destY + b, colour);
  end;
end;

{ Stretch a sprite with nearest neighbour scaling }
procedure sprRefStretch(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);
var
  sx, sy: integer;
  dx, dy: integer;
  srcPos: longint;
  image: PImageRef;
  alpha: byte;
  scaleX, scaleY: double;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;
  image := getImageRefPtr(imgHandle);

  scaleX := image^.width / destWidth;
  scaleY := image^.height / destHeight;

  for dy := 0 to destHeight - 1 do
  for dx := 0 to destWidth - 1 do begin
    if (destX + dx >= vgaWidth) or (destX + dx < 0)
      or (destY + dy >= vgaHeight) or (destY + dy < 0) then continue;

    sx := trunc(dx * scaleX);
    sy := trunc(dy * scaleY);

    srcPos := (sx + sy * image^.width) * 4;
    alpha := image^.dataPtr[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, sx, sy);
    unsafePset(dx + destX, dy + destY, colour);
  end;
end;

procedure sprRefRegionStretch(
  const imgHandle: longint;
  const srcX, srcY, srcWidth, srcHeight: integer;
  const destX, destY, destWidth, destHeight: integer);
var
  sx, sy: integer;
  dx, dy: integer;
  image: PImageRef;
  alpha: byte;
  scaleX, scaleY: double;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;
  image := getImageRefPtr(imgHandle);

  scaleX := srcWidth / destWidth;
  scaleY := srcHeight / destHeight;

  for dy := 0 to destHeight - 1 do
  for dx := 0 to destWidth - 1 do begin
    if (destX + dx >= vgaWidth) or (destX + dx < 0)
      or (destY + dy >= vgaHeight) or (destY + dy < 0) then continue;

    { Map destination pixel to source region }
    sx := srcX + trunc(dx * scaleX);
    sy := srcY + trunc(dy * scaleY);

    if (sx >= image^.width) or (sx < 0)
      or (sy >= image^.height) or (sy < 0) then continue;

    colour := unsafeSprPget(image, sx, sy);
    alpha := colour shr 24;
    if alpha < 255 then continue;

    unsafePset(dx + destX, dy + destY, colour)
  end;
end;

procedure sprRefRegionSolid(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const colour: longword);
var
  image: PImageRef;
  a, b: integer;
  sx, sy: integer;
  srcPos: longint;
  alpha: byte;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImageRefPtr(imgHandle);

  for b:=0 to srcH - 1 do
  for a:=0 to srcW - 1 do begin
    if (destX + a >= vgaWidth) or (destX + a < 0)
      or (destY + b >= vgaHeight) or (destY + b < 0) then continue;

    sx := srcX + a;
    sy := srcY + b;
    srcPos := (sx + sy * image^.width) * 4;

    alpha := image^.dataPtr[srcPos + 3];
    if alpha < 255 then continue;

    { colour := unsafeSprPget(image, sx, sy); }
    unsafePset(destX + a, destY + b, colour);
  end;
end;


procedure sprAlpha(const imgHandle: longint; const x, y: integer; opacity: double);
var
  image: PImageRef;
  px, py: integer;
  colour: longword;
  alpha: byte;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImageRefPtr(imgHandle);
  opacity := clamp(opacity, 0.0, 1.0);

  for py := 0 to image^.height - 1 do
  for px := 0 to image^.width - 1 do begin
    if (x + px >= vgaWidth) or (x + px < 0)
      or (y + py >= vgaHeight) or (y + py < 0) then continue;

    colour := unsafeSprPget(image, px, py);
    alpha := colour shr 24;
    if alpha = 0 then continue;
    
    alpha := trunc(alpha * opacity);
    colour := (colour and $FFFFFF) or (alpha shl 24);

    unsafePsetBlend(x + px, y + py, colour)
  end;
end;

end.

