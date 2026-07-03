{
  ImgRef unit - Part of Posit-92 game engine
  Hevanafa

  Base unit for ImgRefFast and ImgRefComp
  Most of the procedures & functions here are based on Bitmap and SprFast units
}

unit ImgRef;

{$Mode ObjFPC}
{$H+}{$J-}
{$Notes OFF}
{$B-}  { Enable boolean short-circuiting }
{$R-}  { Turn off range checks }
{$Q-}  { Turn off overflow checks }
{Define PanicOnInvalidHandle}

interface

uses P92Core;

const
  MaxImageRefs = 256;

type
  PImageRef = ^TImageRef;
  TImageRef = record
    width: smallint;
    height: smallint;
    allocSize: longword;
    pixelData: PByte;

    status: TAssetStatus;
    errorCode: smallint;
  end;

var
  imageRefs: array[1..MaxImageRefs] of TImageRef;

const
  { SprFlips enum }
  SprFlipNone = 0;
  SprFlipHorizontal = 1;
  SprFlipVertical = 2;
  SprFlipBoth = SprFlipHorizontal or SprFlipVertical;

procedure InitImgRef;
function FindUnusedImageRefSlot: longint;
procedure RegisterImageRef(const imgHandle: longint; const dataPtr: PByte; const w, h: smallint); public name 'RegisterImageRef';

function NewImage(const width, height: smallint): longint;
function CopyImage(const imgHandle: longint): longint;
procedure FreeImage(const imgHandle: longint);

function IsImageSet(const imgHandle: longint): boolean;
procedure AssertImageSet(const varName: string; const imgHandle: longint);
function GetImagePtr(const imgHandle: longint): PImageRef;

function GetImageWidth(const imgHandle: longint): smallint;
procedure SetImageWidth(const imgHandle: longint; const value: smallint);
function GetImageHeight(const imgHandle: longint): smallint;
procedure SetImageHeight(const imgHandle: longint; const value: smallint);

function UnsafeSprPget(const image: PImageRef; const x, y: smallint): longword;
function UnsafeSprGetAlpha(const image: PImageRef; const x, y: smallint): byte;
procedure UnsafeSprPset(const image: PImageRef; const x, y: smallint; const colour: longword);


implementation

uses
  Conv, Logger, Maths, Panic,
{$ifdef WASM}
  WasmHeap,
{$endif}
{$ifdef Windows}
{$endif}
  VGA;

procedure InitImgRef;
var
  a: word;
begin
  for a := 1 to high(imageRefs) do
    imageRefs[a] := default(TImageRef);
end;

function FindUnusedImageRefSlot: longint;
var
  a: longint;
begin
  for a:=1 to high(imageRefs) do
    { if not IsImageSet(a) then begin }
    if imageRefs[a].status = AssetStatusPending then begin
      FindUnusedImageRefSlot := a;
      exit
    end;

  FindUnusedImageRefSlot := -1
end;

procedure RegisterImageRef(const imgHandle: longint; const dataPtr: PByte; const w, h: smallint);
begin
  if (imgHandle < 1) or (imgHandle >= high(imageRefs)) then
    PanicHalt('Invalid image handle: ' + I32Str(imgHandle));

  if (imageRefs[imgHandle].allocSize > 0) then
    PanicHalt('Image handle ' + I32Str(imgHandle) + ' already used! (allocSize > 0)');

  with imageRefs[imgHandle] do begin
    width := w;
    height := h;
    allocSize := longword(w) * longword(h) * 4;
    pixelData := dataPtr;

    status := AssetStatusReady;
    errorCode := 0
  end;
end;

function NewImage(const width, height: smallint): longint;
var
  slot: longint;
  allocSize: longword;
  dataPtr: PByte;
begin
  if width <= 0 then
    PanicHalt('newImage: Invalid width: ' + I32Str(width));

  if height <= 0 then
    PanicHalt('newImage: Invalid height: ' + I32Str(height));

  slot := FindUnusedImageRefSlot;
  if slot < 0 then PanicHalt('Image ref pool is full!');
  
  allocSize := width * height * 4;
  dataPtr := PByte(getmem(allocSize));
  fillchar(dataPtr^, allocSize, 0);

  imageRefs[slot].width := width;
  imageRefs[slot].height := height;
  imageRefs[slot].allocSize := allocSize;
  imageRefs[slot].pixelData := dataPtr;

  NewImage := slot
end;

{ imgHandle: Source image handle }
function CopyImage(const imgHandle: longint): longint;
var
  slot: longint;
  src, dest: PImageRef;
begin
  src := GetImagePtr(imgHandle);
  slot := NewImage(src^.width, src^.height);
  dest := GetImagePtr(slot);

  move(src^.pixelData^, dest^.pixelData^, src^.allocSize);
  CopyImage := slot
end;

procedure FreeImage(const imgHandle: longint);
begin
  if (imgHandle < 1) or (imgHandle >= MaxImageRefs) then exit;
  if imageRefs[imgHandle].pixelData = nil then exit;

{$ifdef WASM}
  WasmFreeMem(imageRefs[imgHandle].pixelData);
{$endif}
{$ifdef Windows}
  FreeMem(imageRefs[imgHandle].dataPtr);
{$endif}

  imageRefs[imgHandle].width := 0;
  imageRefs[imgHandle].height := 0;
  imageRefs[imgHandle].allocSize := 0;
  imageRefs[imgHandle].pixelData := nil
end;


function IsImageSet(const imgHandle: longint): boolean;
begin
  IsImageSet := false;

{$ifdef PanicOnInvalidHandle}
  if imgHandle <= 0 then
    panicHalt('Invalid imgHandle: ' + i32str(imgHandle));
{$else}
  if imgHandle <= 0 then exit;
{$endif}

  { IsImageSet := (imageRefs[imgHandle].width > 0) and (imageRefs[imgHandle].height > 0) }
  { IsImageSet := (imageRefs[imgHandle].allocSize > 0) }
  IsImageSet := imageRefs[imgHandle].status = AssetStatusReady
end;

procedure AssertImageSet(const varName: string; const imgHandle: longint);
begin
  if not IsImageSet(imgHandle) then
    PanicHalt(varName + ' is unset!');
end;

function GetImagePtr(const imgHandle: longint): PImageRef;
begin
  GetImagePtr := @imageRefs[imgHandle]
end;


function GetImageWidth(const imgHandle: longint): smallint;
var
  image: PImageRef;
begin
  GetImageWidth := 0;
  if not IsImageSet(imgHandle) then exit;

  image := GetImagePtr(imgHandle);
  GetImageWidth := image^.width
end;

procedure SetImageWidth(const imgHandle: longint; const value: smallint);
var
  image: PImageRef;
begin
  if not IsImageSet(imgHandle) then exit;
  if value <= 0 then
    PanicHalt('setImageWidth: Invalid width: ' + I32Str(value));

  image := GetImagePtr(imgHandle);

  if value * image^.height * 4 > image^.allocSize then
    PanicHalt('setImageWidth: New size exceeds the allocated buffer!');

  image^.width := value
end;


function GetImageHeight(const imgHandle: longint): smallint;
var
  image: PImageRef;
begin
  GetImageHeight := 0;
  if not IsImageSet(imgHandle) then exit;

  image := GetImagePtr(imgHandle);
  GetImageHeight := image^.height
end;

procedure SetImageHeight(const imgHandle: longint; const value: smallint);
var
  image: PImageRef;
begin
  if not IsImageSet(imgHandle) then exit;
  if value <= 0 then
    PanicHalt('setImageHeight: Invalid width: ' + I32Str(value));

  image := GetImagePtr(imgHandle);

  if image^.width * value * 4 > image^.allocSize then
    PanicHalt('setImageHeight: New size exceeds the allocated buffer!');

  image^.height := value
end;


{ Assuming image isn't nil & the bounds are known }
function UnsafeSprPget(const image: PImageRef; const x, y: smallint): longword;
var
  offset: longword;
begin
  offset := (x + y * image^.width) * 4;

  UnsafeSprPget :=
    (image^.pixelData[offset + 3] shl 24)
    or (image^.pixelData[offset] shl 16)
    or (image^.pixelData[offset + 1] shl 8)
    or image^.pixelData[offset + 2]
end;

function UnsafeSprGetAlpha(const image: PImageRef; const x, y: smallint): byte;
begin
  UnsafeSprGetAlpha := image^.pixelData[
    (x + y * image^.width) * 4 + 3]
end;


procedure UnsafeSprPset(const image: PImageRef; const x, y: smallint; const colour: longword);
var
  offset: longword;
begin
  offset := (x + y * image^.width) * 4;

  { Order: RGBA }
  image^.pixelData[offset] := colour shr 16 and $FF;
  image^.pixelData[offset + 1] := colour shr 8 and $FF;
  image^.pixelData[offset + 2] := colour and $FF;
  image^.pixelData[offset + 3] := colour shr 24 and $FF;
end;

end.
