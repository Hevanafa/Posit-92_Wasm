unit Bitmap;

{Mode TP}  { "inline" keyword and variable initialisation at declaration don't work }
{$Mode ObjFPC}
{$B-}  { Enable boolean short-circuiting }

interface

const
  MaxBitmapData = 65536;

type
  PBitmap = ^TBitmap;
  TBitmap = record
    width, height: word;
    data: array[0..MaxBitmapData-1] of byte;
  end;

{ function loadImageHandle: longint; public name 'loadImageHandle'; }
{ function findEmptyImageSlot: longint; public name 'findEmptyImageSlot'; }
function getEmptyImageSlot: longint; public name 'getEmptyImageSlot';
function newImage(const width, height: integer): longint; public name 'newImage';
procedure freeImage(const imgHandle: longint);

function isImageSet(const imgHandle: longint): boolean; public name 'isImageSet';
procedure debugImage(const imgHandle: longint); public name 'debugImage';
function getImagePtr(const imgHandle: longint): pointer; public name 'getImagePtr';

function getImageWidth(const imgHandle: longint): word; public name 'getImageWidth';
function getImageHeight(const imgHandle: longint): word; public name 'getImageHeight';

procedure spr(const imgHandle: longint; const x, y: integer); public name 'spr';
procedure sprRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer); public name 'sprRegion';

procedure sprStretch(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);
procedure sprScale(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);

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
    if (images[a].width = 0) and (images[a].height = 0) then begin
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


function getImagePtr(const imgHandle: longint): pointer;
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
  isImageSet := false;

  if getImagePtr(imgHandle) <> nil then
    isImageSet := true;
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

procedure spr(const imgHandle: longint; const x, y: integer);
var
  a, b: integer;
  srcPos, destPos: longint;
  image: PBitmap;
  alpha: byte;
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

    destPos := ((a + x) + (b + y) * vgaWidth) * 4;

    { Order: RGBA }
    surface[destPos] := image^.data[srcPos];
    surface[destPos + 1] := image^.data[srcPos + 1];
    surface[destPos + 2] := image^.data[srcPos + 2];
    surface[destPos + 3] := image^.data[srcPos + 3];
  end;
end;

procedure sprRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);
var
  image: PBitmap;
  a, b: integer;
  srcPos, destPos: longint;
  alpha: byte;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for b:=0 to srcH - 1 do
  for a:=0 to srcW - 1 do begin
    if (destX + a >= vgaWidth) or (destX + a < 0)
      or (destY + b >= vgaHeight) or (destY + b < 0) then continue;

    srcPos := ((srcX + a) + (srcY + b) * image^.width) * 4;

    alpha := image^.data[srcPos + 3];
    if alpha < 255 then continue;

    destPos := ((destX + a) + (destY + b) * vgaWidth) * 4;

    { Order: RGBA }
    surface[destPos] := image^.data[srcPos];
    surface[destPos + 1] := image^.data[srcPos + 1];
    surface[destPos + 2] := image^.data[srcPos + 2];
    surface[destPos + 3] := image^.data[srcPos + 3];
  end;
end;

{ Stretch a sprite with nearest neighbour scaling }
procedure sprStretch(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);
var
  sx, sy: integer;
  dx, dy: integer;
  srcPos, destPos: longint;
  image: PBitmap;
  alpha: byte;
  scaleX, scaleY: double;
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

    destPos := ((dx + destX) + (dy + destY) * vgaWidth) * 4;

    { Order: RGBA }
    surface[destPos] := image^.data[srcPos];
    surface[destPos + 1] := image^.data[srcPos + 1];
    surface[destPos + 2] := image^.data[srcPos + 2];
    surface[destPos + 3] := image^.data[srcPos + 3];
  end;
end;

procedure sprScale(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);
begin
  sprStretch(imgHandle, destX, destY, destWidth, destHeight)
end;


function sprPget(const imgHandle: longint; const x, y: integer): longword;
var
  offset: longword;
  a, r, g, b: byte;
  image: PBitmap;
begin
  sprPget := 0;
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  if (x < 0) or (x >= image^.width)
    or (y < 0) or (y >= image^.height) then exit;

  offset := (x + y * image^.width) * 4;
  r := image^.data[offset];
  g := image^.data[offset + 1];
  b := image^.data[offset + 2];
  a := image^.data[offset + 3];

  sprPget := (a shl 24) or (r shl 16) or (g shl 8) or b
end;

{ Assuming image isn't nil }
function unsafeSprPget(const image: PBitmap; const x, y: integer): longword; inline;
var
  offset: longword;
begin
  offset := (x + y * image^.width) * 4;

  unsafeSprPget := (image^.data[offset + 3] shl 24)
    or (image^.data[offset] shl 16)
    or (image^.data[offset + 1] shl 8)
    or image^.data[offset + 2]
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

{
initialization

nextImageHandle := 1;
}

end.
