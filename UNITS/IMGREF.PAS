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

function newImage(const width, height: integer): longint;
function copyImage(const imgHandle: longint): longint;
procedure freeImage(const imgHandle: longint);

function isImageSet(const imgHandle: longint): boolean;
function getImagePtr(const imgHandle: longint): PImageRef;

function getImageWidth(const imgHandle: longint): word;
function getImageHeight(const imgHandle: longint): word;

function unsafeSprPget(const image: PImageRef; const x, y: integer): longword;
function unsafeSprGetAlpha(const image: PImageRef; const x, y: integer): byte;
procedure unsafeSprPset(const image: PImageRef; const x, y: integer; const colour: longword);


implementation

uses Logger, Maths, Panic, VGA, WasmHeap;

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

function newImage(const width, height: integer): longint;
var
  slot: longint;
  dataPtr: PByte;
  byteSize: longword;
begin
  writeLog('Calling newImage');
  writeLogI32(width);
  writeLogI32(height);

  byteSize := width * height * 4;
  dataPtr := PByte(WasmGetMem(byteSize));

  fillchar(dataPtr^, byteSize, 0);

  slot := findEmptyImageRefSlot;
  if slot < 0 then panicHalt('Image ref pool is full!');

  imageRefs[slot].width := width;
  imageRefs[slot].height := height;
  imageRefs[slot].dataPtr := dataPtr;

  newImage := slot
end;

{ imgHandle: Source image handle }
function copyImage(const imgHandle: longint): longint;
var
  slot: longint;
  src, dest: PImageRef;
begin
  src := getImagePtr(imgHandle);
  slot := newImage(src^.width, src^.height);
  dest := getImagePtr(slot);

  move(src^.dataPtr^, dest^.dataPtr^, src^.width * src^.height * 4);
  copyImage := slot
end;

procedure freeImage(const imgHandle: longint);
begin
  if (imgHandle < 0) or (imgHandle >= MaxImageRefs) then exit;
  if imageRefs[imgHandle].dataPtr = nil then exit;

  WasmFreeMem(imageRefs[imgHandle].dataPtr);

  imageRefs[imgHandle].width := 0;
  imageRefs[imgHandle].height := 0;
  imageRefs[imgHandle].dataPtr := nil;
end;


function isImageSet(const imgHandle: longint): boolean;
begin
  isImageSet := (imageRefs[imgHandle].width > 0) and (imageRefs[imgHandle].height > 0)
end;

function getImagePtr(const imgHandle: longint): PImageRef;
begin
  getImagePtr := @imageRefs[imgHandle]
end;

function getImageWidth(const imgHandle: longint): word;
var
  image: PImageRef;
begin
  getImageWidth := 0;
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);
  getImageWidth := image^.width
end;

function getImageHeight(const imgHandle: longint): word;
var
  image: PImageRef;
begin
  getImageHeight := 0;
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);
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

function unsafeSprGetAlpha(const image: PImageRef; const x, y: integer): byte;
begin
  unsafeSprGetAlpha := image^.dataPtr[
    (x + y * image^.width) * 4 + 3]
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

end.
