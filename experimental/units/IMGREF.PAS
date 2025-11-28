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

procedure registerImageRef(const imgHandle: longint; const dataPtr: PByte; const w, h: integer); public name 'registerImageRef';
function getImageRefPtr(const imgHandle: longint): PImageRef;

function getImageWidth(const imgHandle: longint): word;
function getImageHeight(const imgHandle: longint): word;

{ Rendering procedures }
{ spr with TImageRef }
procedure sprRef(const imgHandle: longint; const x, y: integer);

procedure sprRefRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);

procedure sprRefRegionSolid(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const colour: longword);


implementation

uses Logger, Panic, VGA;

const
  MaxImageRefs = 256;

var
  imageRefs: array[1..MaxImageRefs] of TImageRef;


function isImageSet(const imgHandle: longint): boolean;
begin
  isImageSet := (imageRefs[imgHandle].width > 0) and (imageRefs[imgHandle].height > 0)
end;

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


end.

