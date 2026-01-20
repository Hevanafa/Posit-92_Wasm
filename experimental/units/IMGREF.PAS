{
  ImgRef unit - Part of Posit-92 game engine
  Hevanafa

  Base unit for ImgRefFast and ImgRefComp
  Most of the procedures & functions here are based on Bitmap and SprFast units
}

unit ImgRef;

{$Mode TP}
{$Notes OFF}
{$B-}  { Enable boolean short-circuiting }
{$R-}  { Turn off range checks }
{$Q-}  { Turn off overflow checks }
{Define PanicOnInvalidHandle}

interface

type
  PImageRef = ^TImageRef;
  TImageRef = record
    width: integer;
    height: integer;
    allocSize: longword;
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

function getImageWidth(const imgHandle: longint): integer;
procedure setImageWidth(const imgHandle: longint; const value: integer);
function getImageHeight(const imgHandle: longint): integer;
procedure setImageHeight(const imgHandle: longint; const value: integer);

function unsafeSprPget(const image: PImageRef; const x, y: integer): longword;
function unsafeSprGetAlpha(const image: PImageRef; const x, y: integer): byte;
procedure unsafeSprPset(const image: PImageRef; const x, y: integer; const colour: longword);


implementation

uses
  Conv, Logger, Maths, Panic,
{$ifdef WASM}
  WasmHeap,
{$endif}
{$ifdef WIN64}
{$endif}
  VGA;

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
  imageRefs[imgHandle].allocSize := w * h * 4;
  imageRefs[imgHandle].dataPtr := dataPtr
end;

function newImage(const width, height: integer): longint;
var
  slot: longint;
  allocSize: longword;
  dataPtr: PByte;
begin
  if width <= 0 then
    panicHalt('newImage: Invalid width: ' + i32str(width));

  if height <= 0 then
    panicHalt('newImage: Invalid height: ' + i32str(height));

  slot := findEmptyImageRefSlot;
  if slot < 0 then panicHalt('Image ref pool is full!');
  
  allocSize := width * height * 4;
  dataPtr := PByte(getmem(allocSize));
  fillchar(dataPtr^, allocSize, 0);

  imageRefs[slot].width := width;
  imageRefs[slot].height := height;
  imageRefs[slot].allocSize := allocSize;
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

  move(src^.dataPtr^, dest^.dataPtr^, src^.allocSize);
  copyImage := slot
end;

procedure freeImage(const imgHandle: longint);
begin
  if (imgHandle < 1) or (imgHandle >= MaxImageRefs) then exit;
  if imageRefs[imgHandle].dataPtr = nil then exit;

{$ifdef WASM}
  WasmFreeMem(imageRefs[imgHandle].dataPtr);
{$endif}
{$ifdef WIN64}
  FreeMem(imageRefs[imgHandle].dataPtr);
{$endif}

  imageRefs[imgHandle].width := 0;
  imageRefs[imgHandle].height := 0;
  imageRefs[imgHandle].allocSize := 0;
  imageRefs[imgHandle].dataPtr := nil
end;


function isImageSet(const imgHandle: longint): boolean;
begin
  isImageSet := false;

{$ifdef PanicOnInvalidHandle}
  if imgHandle <= 0 then
    panicHalt('Invalid imgHandle: ' + i32str(imgHandle));
{$else}
  if imgHandle <= 0 then exit;
{$endif}

  { isImageSet := (imageRefs[imgHandle].width > 0) and (imageRefs[imgHandle].height > 0) }
  isImageSet := (imageRefs[imgHandle].allocSize > 0)
end;

function getImagePtr(const imgHandle: longint): PImageRef;
begin
  getImagePtr := @imageRefs[imgHandle]
end;

function getImageWidth(const imgHandle: longint): integer;
var
  image: PImageRef;
begin
  getImageWidth := 0;
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);
  getImageWidth := image^.width
end;

procedure setImageWidth(const imgHandle: longint; const value: integer);
var
  image: PImageRef;
begin
  if not isImageSet(imgHandle) then exit;
  if value <= 0 then
    panicHalt('setImageWidth: Invalid width: ' + i32str(value));

  image := getImagePtr(imgHandle);

  if value * image^.height * 4 > image^.allocSize then
    panicHalt('setImageWidth: New size exceeds the allocated buffer!');

  image^.width := value
end;


function getImageHeight(const imgHandle: longint): integer;
var
  image: PImageRef;
begin
  getImageHeight := 0;
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);
  getImageHeight := image^.height
end;

procedure setImageHeight(const imgHandle: longint; const value: integer);
var
  image: PImageRef;
begin
  if not isImageSet(imgHandle) then exit;
  if value <= 0 then
    panicHalt('setImageHeight: Invalid width: ' + i32str(value));

  image := getImagePtr(imgHandle);

  if image^.width * value * 4 > image^.allocSize then
    panicHalt('setImageHeight: New size exceeds the allocated buffer!');

  image^.height := value
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
