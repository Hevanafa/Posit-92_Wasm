unit Bitmap;

{$Mode TP}
{$B-}  { Enable boolean short-circuiting }

interface

const
  MaxBitmapData = 65536;

  { SprFlips enum }
  SprFlipNone = 0;
  SprFlipHorizontal = 1;
  SprFlipVertical = 2;
  SprFlipBoth = SprFlipHorizontal or SprFlipVertical;

type
  PBitmap = ^TBitmap;
  TBitmap = record
    width, height: word;
    data: array[0..MaxBitmapData-1] of byte;
  end;

function getMaxBitmapData: longword; public name 'getMaxBitmapData';

{ function loadImageHandle: longint; public name 'loadImageHandle'; }
{ function findEmptyImageSlot: longint; public name 'findEmptyImageSlot'; }
function getEmptyImageSlot: longint; public name 'getEmptyImageSlot';
function newImage(const width, height: integer): longint; public name 'newImage';
procedure freeImage(const imgHandle: longint);

function isImageSet(const imgHandle: longint): boolean; public name 'isImageSet';
procedure debugImage(const imgHandle: longint); public name 'debugImage';
function getImagePtr(const imgHandle: longint): PBitmap; public name 'getImagePtr';

function getImageWidth(const imgHandle: longint): word; public name 'getImageWidth';
function getImageHeight(const imgHandle: longint): word; public name 'getImageHeight';

procedure spr(const imgHandle: longint; const x, y: integer); public name 'spr';
procedure sprRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer); public name 'sprRegion';

procedure sprFlip(const imgHandle: longint; const x, y: integer; const flip: integer);
procedure sprStretch(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);
procedure sprScale(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);

{ rotation is in radians }
procedure sprRotate(const imgHandle: longint; const cx, cy: integer; const rotation: double);

procedure sprBlend(const imgHandle: longint; const x, y: integer); public name 'sprBlend';
procedure sprRegionBlend(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer); public name 'sprRegionBlend';


implementation

uses
  Conv, Logger, Panic, VGA;

{ Bitmap operations }
var
  images: array[1..10] of TBitmap;
  { nextImageHandle: longint = 1; }

function getMaxBitmapData: longword;
begin
  getMaxBitmapData := MaxBitmapData
end;

{
function loadImageHandle: longint;
begin
  loadImageHandle := nextImageHandle;
  inc(nextImageHandle)
end;
}

function getEmptyImageSlot: longint;
var
  a: longint;
begin
  for a:=1 to high(images) do
    if not isImageSet(a) then begin
      getEmptyImageSlot := a;
      exit
    end;

  getEmptyImageSlot := -1
end;

{
function getEmptyImageSlot: longint;
var
  a: longint;
begin
  for a:=1 to high(images) do
    if images[a] = nil then begin
      getEmptyImageSlot := a;
      exit
    end;

  getEmptyImageSlot := -1
end;
}

procedure freeImage(const imgHandle: longint);
begin
  if (imgHandle < low(images)) or (imgHandle > high(images)) then exit;
  { images[imgHandle] := nil }
  images[imgHandle].width := 0;
  images[imgHandle].height := 0;
end;

function newImage(const width, height: integer): longint;
var
  slot: longint;
  bmp: TBitmap;
begin
  if width * height * 4 > MaxBitmapData then
    panicHalt('newImage: Bitmap is too large!');

  slot := getEmptyImageSlot;

  bmp.width := width;
  bmp.height := height;
  fillchar(bmp.data, sizeof(bmp.data), 0);

  images[slot] := bmp;
  newImage := slot
end;


function getImagePtr(const imgHandle: longint): PBitmap;
var
  idx: integer;
begin
  idx := imgHandle;

  {
  writeLog('getImagePtr imgHandle: ' + i32str(imgHandle));
  writeLog('getImagePtr idx: ' + i32str(idx));
  }

  if (low(images) <= idx) and (idx < high(images)) then
    getImagePtr := @images[idx]
  else
    getImagePtr := nil;
end;

function isImageSet(const imgHandle: longint): boolean;
begin
  { isImageSet := (imgHandle < 0) }
  {
  isImageSet := false;
  if getImagePtr(imgHandle) <> nil then
    isImageSet := true;
  }
  isImageSet := (images[imgHandle].width > 0) and (images[imgHandle].height > 0)
end;


procedure debugImage(const imgHandle: longint);
var
  image: PBitmap;
  a: integer;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);
  writeLogI32(image^.width);
  writeLogI32(image^.height);

  { Debug the first 5 pixels }
  for a:=0 to 19 do
    writeLogI32(image^.data[a]);
end;


{
function allocImageData(const size: integer): pointer;
var
  ptr: pointer;
begin
  Important: This always crashes on WebAssembly
  getmem(ptr, size);
  allocImageData := ptr
end;
}

function getImageWidth(const imgHandle: longint): word;
var
  image: PBitmap;
begin
  getImageWidth := 0;
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);
  getImageWidth := image^.width
end;

function getImageHeight(const imgHandle: longint): word;
var
  image: PBitmap;
begin
  getImageHeight := 0;
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);
  getImageHeight := image^.height
end;

{ Assuming image isn't nil & the bounds are known }
function unsafeSprPget(const image: PBitmap; const x, y: integer): longword;
var
  offset: longword;
begin
  offset := (x + y * image^.width) * 4;

  unsafeSprPget := (image^.data[offset + 3] shl 24)
    or (image^.data[offset] shl 16)
    or (image^.data[offset + 1] shl 8)
    or image^.data[offset + 2]
end;

function sprPget(const imgHandle: longint; const x, y: integer): longword;
var
  image: PBitmap;
begin
  sprPget := 0;

  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  if (x < 0) or (x >= image^.width)
    or (y < 0) or (y >= image^.height) then exit;

  sprPget := unsafeSprPget(image, x, y)
end;


procedure spr(const imgHandle: longint; const x, y: integer);
var
  a, b: integer;
  srcPos: longint;
  image: PBitmap;
  alpha: byte;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for b:=0 to image^.height - 1 do
  for a:=0 to image^.width - 1 do begin
    if (x + a >= vgaWidth) or (x + a < 0)
      or (y + b >= vgaHeight) or (y + b < 0) then continue;

    srcPos := (a + b * image^.width) * 4;
    alpha := image^.data[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, a, b);
    unsafePset(x + a, y + b, colour);
  end;
end;

procedure sprRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);
var
  image: PBitmap;
  a, b: integer;
  sx, sy: integer;
  srcPos: longint;
  alpha: byte;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for b:=0 to srcH - 1 do
  for a:=0 to srcW - 1 do begin
    if (destX + a >= vgaWidth) or (destX + a < 0)
      or (destY + b >= vgaHeight) or (destY + b < 0) then continue;

    sx := srcX + a;
    sy := srcY + b;
    srcPos := (sx + sy * image^.width) * 4;

    alpha := image^.data[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, sx, sy);
    unsafePset(destX + a, destY + b, colour);
  end;
end;

{ flip: use SprFlips enum }
procedure sprFlip(const imgHandle: longint; const x, y: integer; const flip: integer);
var
  sx, sy: integer;
  dx, dy: integer;
  srcPos: longint;
  image: PBitmap;
  alpha: byte;
  colour: longword;
begin
  if flip = SprFlipNone then begin
    spr(imgHandle, x, y);
    exit
  end;

  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for sy := 0 to image^.height - 1 do
  for sx := 0 to image^.width - 1 do begin
    srcPos := (sx + sy * image^.width) * 4;
    alpha := image^.data[srcPos + 3];
    if alpha < 255 then continue;

    dx := x + sx;
    dy := y + sy;

    case flip of
      SprFlipHorizontal:
        dx := x + image^.width - sx - 1;
      SprFlipVertical:
        dy := y + image^.height - sy - 1;
      else begin
        dx := x + image^.width - sx - 1;
        dy := y + image^.height - sy - 1;
      end
    end;

    if (dx >= vgaWidth) or (dx < 0)
      or (dy >= vgaHeight) or (dy < 0) then continue;

    colour := unsafeSprPget(image, sx, sy);
    unsafePset(dx, dy, colour);
  end;
end;

{ Stretch a sprite with nearest neighbour scaling }
procedure sprStretch(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);
var
  sx, sy: integer;
  dx, dy: integer;
  srcPos: longint;
  image: PBitmap;
  alpha: byte;
  scaleX, scaleY: double;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;
  image := getImagePtr(imgHandle);

  scaleX := image^.width / destWidth;
  scaleY := image^.height / destHeight;

  for dy := 0 to destHeight - 1 do
  for dx := 0 to destWidth - 1 do begin
    if (destX + dx >= vgaWidth) or (destX + dx < 0)
      or (destY + dy >= vgaHeight) or (destY + dy < 0) then continue;

    sx := trunc(dx * scaleX);
    sy := trunc(dy * scaleY);

    srcPos := (sx + sy * image^.width) * 4;
    alpha := image^.data[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, sx, sy);
    unsafePset(dx + destX, dy + destY, colour);
  end;
end;

procedure sprScale(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);
begin
  sprStretch(imgHandle, destX, destY, destWidth, destHeight)
end;


procedure sprRotate(const imgHandle: longint; const cx, cy: integer; const rotation: double);
var
  sx, sy: double;
  dx, dy: integer;
  srcPos: longint;
  srcX, srcY: integer;
  image: PBitmap;

  alpha: byte;
  colour: longword;

  cosAngle, sinAngle: double;
  halfW, halfH: integer;
  maxRadius: integer;
begin
  if not isImageSet(imgHandle) then exit;
  image := getImagePtr(imgHandle);

  { Negative for inverse transform }
  cosAngle := cos(-rotation);
  sinAngle := sin(-rotation);

  halfW := image^.width div 2;
  halfH := image^.height div 2;

  maxRadius := trunc(sqrt(halfW * halfW + halfH * halfH)) + 1;
  
  for dy := -maxRadius to maxRadius do
  for dx := -maxRadius to maxRadius do begin
    if (cx + dx < 0) or (cx + dx >= vgaWidth)
      or (cy + dy < 0) or (cy + dy >= vgaHeight) then continue;

    sx := dx * cosAngle - dy * sinAngle;
    sy := dx * sinAngle + dy * cosAngle;

    srcX := trunc(sx) + halfW;
    srcY := trunc(sy) + halfH;

    if (srcX < 0) or (srcX >= image^.width)
      or (srcY < 0) or (srcY >= image^.height) then continue;

    srcPos := (srcX + srcY * image^.width) * 4;
    alpha := image^.data[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, srcX, srcY);
    unsafePset(cx + dx, cy + dy, colour)
  end;
end;


procedure sprBlend(const imgHandle: longint; const x, y: integer);
var
  image: PBitmap;
  px, py: integer;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for py := 0 to image^.height - 1 do
  for px := 0 to image^.width - 1 do begin
    if (x + px >= vgaWidth) or (x + px < 0)
      or (y + py >= vgaHeight) or (y + py < 0) then continue;

    colour := unsafeSprPget(image, px, py);
    psetBlend(x + px, y + py, colour)
  end;
end;

procedure sprRegionBlend(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);
var
  px, py: integer;
  colour: longword;
  image: PBitmap;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for py := 0 to srcH - 1 do
  for px := 0 to srcW - 1 do begin
    if (destX + px >= vgaWidth) or (destX + px < 0)
      or (destY + py >= vgaHeight) or (destY + py < 0) then continue;

    colour := unsafeSprPget(image, srcX + px, srcY + py);
    psetBlend(destX + px, destY + py, colour)
  end;
end;

end.
