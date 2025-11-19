unit Bitmap;

{$B-}  { Enable boolean short-circuiting }

interface

type
  PBitmap = ^TBitmap;
  TBitmap = record
    width, height: word;
    data: array[0..63999] of byte;
  end;

function loadImageHandle: longint; public name 'loadImageHandle';
function isImageSet(const imgHandle: longint): boolean; public name 'isImageSet';
procedure debugImage(const imgHandle: longint); public name 'debugImage';
function getImagePtr(const imgHandle: longint): pointer; public name 'getImagePtr';

procedure spr(const imgHandle: longint; const x, y: integer); public name 'spr';
procedure sprRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer); public name 'sprRegion';

procedure sprBlend(const imgHandle: longint; const x, y: integer); public name 'sprBlend';
procedure sprRegionBlend(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer); public name 'sprRegionBlend';


implementation

uses
  Conv, Logger, VGA;

{ Bitmap operations }
var
  images: array[1..10] of TBitmap;
  nextImageHandle: longint = 1;

function loadImageHandle: longint;
begin
  loadImageHandle := nextImageHandle;
  inc(nextImageHandle)
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

  if (1 <= idx) and (idx < nextImageHandle) then
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

procedure spr(const imgHandle: longint; const x, y: integer);
var
  a, b: integer;
  srcPos, destPos: longint;
  image: PBitmap;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for b:=0 to image^.height - 1 do
  for a:=0 to image^.width - 1 do begin
    if (x + a >= vgaWidth) or (x + a < 0)
      or (y + b >= vgaHeight) or (y + b < 0) then continue;

    srcPos := (a + b * image^.width) * 4;
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
  a, b: integer;
  srcPos, destPos: longint;
  image: PBitmap;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for b:=0 to srcH - 1 do
  for a:=0 to srcW - 1 do begin
    if (destX + a >= vgaWidth) or (destX + a < 0)
      or (destY + b >= vgaHeight) or (destY + b < 0) then continue;

    srcPos := ((srcX + a) + (srcY + b) * image^.width) * 4;
    destPos := ((destX + a) + (destY + b) * vgaWidth) * 4;

    { Order: RGBA }
    surface[destPos] := image^.data[srcPos];
    surface[destPos + 1] := image^.data[srcPos + 1];
    surface[destPos + 2] := image^.data[srcPos + 2];
    surface[destPos + 3] := image^.data[srcPos + 3];
  end;
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

    colour := sprPget(imgHandle, px, py);
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
begin
  if not isImageSet(imgHandle) then exit;

  for py := 0 to srcH - 1 do
  for px := 0 to srcW - 1 do begin
    if (destX + px >= vgaWidth) or (destX + px < 0)
      or (destY + py >= vgaHeight) or (destY + py < 0) then continue;

    colour := sprPget(imgHandle, srcX + px, srcY + py);
    psetBlend(destX + px, destY + py, colour)
  end;
end;

end.
