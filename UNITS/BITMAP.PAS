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
function getImagePtr(const imgHandle: longint): pointer; public name 'getImagePtr';
procedure spr(const imgHandle: longint; const x, y: integer); public name 'spr';
procedure sprRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer); public name 'sprRegion';

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
begin
  if (1 <= imgHandle) and (imgHandle < nextImageHandle) then
    getImagePtr := @images[imgHandle]
  else
    getImagePtr := nil;
end;

procedure debugImage(const imgHandle: longint); public name 'debugImage';
var
  image: PBitmap;
  a: integer;
begin
  image := getImagePtr(imgHandle);
  if image = nil then exit;

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
  image := getImagePtr(imgHandle);
  if image = nil then exit;

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
  image := getImagePtr(imgHandle);
  if image = nil then exit;

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

procedure sprBlend(const imgHandle: longint; const x, y: integer);
var
  image: PBitmap;
  px, py: integer;
  srcPos: longint;
  colour: longword;
  a, r, g, b: byte;
begin
  image := getImagePtr(imgHandle);
  if image = nil then exit;

  for py := 0 to image^.height - 1 do
  for px := 0 to image^.width - 1 do begin
    if (x + a >= vgaWidth) or (x + a < 0)
      or (y + b >= vgaHeight) or (y + b < 0) then continue;

    srcPos := (px + py * image^.width) * 4;
    r := image^.data[srcPos];
    g := image^.data[srcPos + 1];
    b := image^.data[srcPos + 2];
    a := image^.data[srcPos + 3];

    colour := (a shl 24) or (r shl 16) or (g shl 8) or b;
    psetBlend(x + px, y + py, colour)
  end;
end;

end.
