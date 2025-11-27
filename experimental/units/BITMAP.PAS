{
  Bitmap unit
  Part of Posit-92 framework
  By Hevanafa, 22-11-2025
}

unit Bitmap;

{Mode TP}
{$Mode ObjFPC}
{$B-}  { Enable boolean short-circuiting }
{$R-}  { Turn off range checks }
{$Q-}  { Turn off overflow checks }

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

  TImageRef = record
    handle: longint;  { Index on JS }
    dataPtr: pointer;
    width: integer;
    height: integer;
  end;

function getMaxBitmapData: longword;
function findEmptyImageSlot: longint;

procedure registerImageRef(const handle: longint; const dataPtr: pointer; const w, h: integer); public name 'registerImageRef';
function getImageRef(const idx: integer): TImageRef;
function getImageRefCount: integer;

function newImage(const width, height: integer): longint; public name 'newImage';
function copyImage(const imgHandle: longint): longint;
procedure freeImage(const imgHandle: longint);

function isImageSet(const imgHandle: longint): boolean;
procedure debugImage(const imgHandle: longint); public name 'debugImage';
function getImagePtr(const imgHandle: longint): PBitmap; public name 'getImagePtr';

function getImageWidth(const imgHandle: longint): word;
function getImageHeight(const imgHandle: longint): word;

function unsafeSprPget(const image: PBitmap; const x, y: integer): longword;
function sprPget(const imgHandle: longint; const x, y: integer): longword;

procedure unsafeSprPset(const image: PBitmap; const x, y: integer; const colour: longword);
procedure sprPset(const imgHandle: longint; const x, y: integer; const colour: longword);


implementation

uses
  Conv, Logger, Maths, Panic, VGA;

const
  MaxImageRefs = 256;

{ Bitmap operations }
var
  { bitmap pool }
  images: array[1..16] of TBitmap;

  imageRefs: array[1..MaxImageRefs] of TImageRef;
  imageRefCount: integer = 0;


function getMaxBitmapData: longword;
begin
  getMaxBitmapData := MaxBitmapData
end;

function findEmptyImageSlot: longint;
var
  a: longint;
begin
  for a:=1 to high(images) do
    if not isImageSet(a) then begin
      findEmptyImageSlot := a;
      exit
    end;

  findEmptyImageSlot := -1
end;


procedure registerImageRef(const handle: longint; const dataPtr: pointer; const w, h: integer);
begin
  if imageRefCount >= MaxImageRefs then
    panicHalt('Image ref pool is full!');

  writeLog('registerImageRef: handle, w, h');
  writeLogI32(handle);
  writeLogI32(w);
  writeLogI32(h);

  imageRefs[imageRefCount].handle := handle;
  imageRefs[imageRefCount].dataPtr := dataPtr;
  imageRefs[imageRefCount].width := w;
  imageRefs[imageRefCount].height := h;

  inc(imageRefCount)
end;

function getImageRef(const idx: integer): TImageRef;
begin
  getImageRef := imageRefs[idx]
end;

function getImageRefCount: integer;
begin
  getImageRefCount := imageRefCount
end;


function newImage(const width, height: integer): longint;
var
  slot: longint;
  bmp: TBitmap;
begin
  if width * height * 4 > MaxBitmapData then
    panicHalt('newImage: Bitmap is too large!');

  slot := findEmptyImageSlot;

  bmp.width := width;
  bmp.height := height;
  fillchar(bmp.data, sizeof(bmp.data), 0);

  images[slot] := bmp;
  newImage := slot
end;

function copyImage(const imgHandle: longint): longint;
var
  slot: longint;
  src, dest: PBitmap;
  a, b: integer;
begin
  src := getImagePtr(imgHandle);
  slot := newImage(src^.width, src^.height);
  dest := getImagePtr(slot);

  for b:=0 to src^.height - 1 do
  for a:=0 to src^.width - 1 do
    unsafeSprPset(dest, a, b, unsafeSprPget(src, a, b));

  copyImage := slot
end;

procedure freeImage(const imgHandle: longint);
begin
  if (imgHandle < low(images)) or (imgHandle > high(images)) then exit;

  images[imgHandle].width := 0;
  images[imgHandle].height := 0;
end;


function getImagePtr(const imgHandle: longint): PBitmap;
var
  idx: integer;
begin
  idx := imgHandle;

  if (low(images) <= idx) and (idx < high(images)) then
    getImagePtr := @images[idx]
  else
    getImagePtr := nil;
end;


function isImageSet(const imgHandle: longint): boolean;
begin
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

{ Assuming image isn't nil & the bounds are known }
procedure unsafeSprPset(const image: PBitmap; const x, y: integer; const colour: longword);
var
  offset: longword;
begin
  offset := (x + y * image^.width) * 4;

  { Order: RGBA }
  image^.data[offset] := colour shr 16 and $FF;
  image^.data[offset + 1] := colour shr 8 and $FF;
  image^.data[offset + 2] := colour and $FF;
  image^.data[offset + 3] := colour shr 24 and $FF;
end;

procedure sprPset(const imgHandle: longint; const x, y: integer; const colour: longword);
var
  image: PBitmap;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  if (x < 0) or (x >= image^.width)
    or (y < 0) or (y >= image^.height) then exit;

  unsafeSprPset(image, x, y, colour)
end;


end.
