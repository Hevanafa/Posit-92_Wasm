{
  SoftwareTex unit - Part of Posit-92 game engine
  Hevanafa

  Base unit for ImgRefFast and ImgRefComp
  Most of the procedures & functions here are based on Bitmap and SprFast units
}

unit SoftwareTex;

{$Mode ObjFPC}
{$H+}{$J-}
{$Notes OFF}
{$B-}  { Enable boolean short-circuiting }
{$R-}  { Turn off range checks }
{$Q-}  { Turn off overflow checks }
{Define PanicOnInvalidHandle}

interface

uses P92AssetRegistry;

const
  MaxTextures = 256;

type
  PSoftwareTex = ^TSoftwareTex;
  TSoftwareTex = record
    width: smallint;
    height: smallint;
    allocSize: longword;
    pixelData: PByte;

    status: TAssetStatus;
    errorCode: smallint;
  end;

var
  imageRefs: array[1..MaxTextures] of TSoftwareTex;

const
  { SprFlips enum }
  SprFlipNone = 0;
  SprFlipHorizontal = 1;
  SprFlipVertical = 2;
  SprFlipBoth = SprFlipHorizontal or SprFlipVertical;

procedure InitSoftwareTex;
function FindUnusedTextureSlot: longint;

function NewTexture(const width, height: smallint): longint;
function CopyTexture(const imgHandle: longint): longint;
procedure FreeTexture(const imgHandle: longint);

function IsTextureSet(const imgHandle: longint): boolean;
procedure AssertTextureSet(const varName: string; const imgHandle: longint);
function GetTexturePtr(const imgHandle: longint): PSoftwareTex;

function GetTextureWidth(const imgHandle: longint): smallint;
procedure SetTextureWidth(const imgHandle: longint; const value: smallint);
function GetTextureHeight(const imgHandle: longint): smallint;
procedure SetTextureHeight(const imgHandle: longint; const value: smallint);

function UnsafeSprPget(const image: PSoftwareTex; const x, y: smallint): longword;
function UnsafeSprGetAlpha(const image: PSoftwareTex; const x, y: smallint): byte;
procedure UnsafeSprPset(const image: PSoftwareTex; const x, y: smallint; const colour: longword);


implementation

uses
  Conv, Logger, Maths, Panic,
{$ifdef WASM}
  WasmHeap,
{$endif}
{$ifdef Windows}
{$endif}
  VGA;

procedure InitSoftwareTex;
var
  a: word;
begin
  for a := 1 to high(imageRefs) do
    imageRefs[a] := default(TSoftwareTex);
end;

function FindUnusedTextureSlot: longint;
var
  a: longint;
begin
  for a:=1 to high(imageRefs) do
    { if not IsTextureSet(a) then begin }
    if imageRefs[a].status = AssetStatusPending then begin
      FindUnusedTextureSlot := a;
      exit
    end;

  FindUnusedTextureSlot := -1
end;

function NewTexture(const width, height: smallint): longint;
var
  slot: longint;
  allocSize: longword;
  dataPtr: PByte;
begin
  if width <= 0 then
    PanicHalt('newImage: Invalid width: ' + I32Str(width));

  if height <= 0 then
    PanicHalt('newImage: Invalid height: ' + I32Str(height));

  slot := FindUnusedTextureSlot;
  if slot < 0 then PanicHalt('Image ref pool is full!');
  
  allocSize := width * height * 4;
  dataPtr := PByte(getmem(allocSize));
  fillchar(dataPtr^, allocSize, 0);

  imageRefs[slot].width := width;
  imageRefs[slot].height := height;
  imageRefs[slot].allocSize := allocSize;
  imageRefs[slot].pixelData := dataPtr;

  NewTexture := slot
end;

{ imgHandle: Source image handle }
function CopyTexture(const imgHandle: longint): longint;
var
  slot: longint;
  src, dest: PSoftwareTex;
begin
  src := GetTexturePtr(imgHandle);
  slot := NewTexture(src^.width, src^.height);
  dest := GetTexturePtr(slot);

  move(src^.pixelData^, dest^.pixelData^, src^.allocSize);
  CopyTexture := slot
end;

procedure FreeTexture(const imgHandle: longint);
begin
  if (imgHandle < 1) or (imgHandle >= MaxTextures) then exit;
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


function IsTextureSet(const imgHandle: longint): boolean;
begin
  IsTextureSet := false;

{$ifdef PanicOnInvalidHandle}
  if imgHandle <= 0 then
    panicHalt('Invalid imgHandle: ' + i32str(imgHandle));
{$else}
  if imgHandle <= 0 then exit;
{$endif}

  { IsTextureSet := (imageRefs[imgHandle].width > 0) and (imageRefs[imgHandle].height > 0) }
  { IsTextureSet := (imageRefs[imgHandle].allocSize > 0) }
  IsTextureSet := imageRefs[imgHandle].status = AssetStatusReady
end;

procedure AssertTextureSet(const varName: string; const imgHandle: longint);
begin
  if not IsTextureSet(imgHandle) then
    PanicHalt(varName + ' is unset!');
end;

function GetTexturePtr(const imgHandle: longint): PSoftwareTex;
begin
  GetTexturePtr := @imageRefs[imgHandle]
end;


function GetTextureWidth(const imgHandle: longint): smallint;
var
  image: PSoftwareTex;
begin
  GetTextureWidth := 0;
  if not IsTextureSet(imgHandle) then exit;

  image := GetTexturePtr(imgHandle);
  GetTextureWidth := image^.width
end;

procedure SetTextureWidth(const imgHandle: longint; const value: smallint);
var
  image: PSoftwareTex;
begin
  if not IsTextureSet(imgHandle) then exit;
  if value <= 0 then
    PanicHalt('setImageWidth: Invalid width: ' + I32Str(value));

  image := GetTexturePtr(imgHandle);

  if value * image^.height * 4 > image^.allocSize then
    PanicHalt('setImageWidth: New size exceeds the allocated buffer!');

  image^.width := value
end;


function GetTextureHeight(const imgHandle: longint): smallint;
var
  image: PSoftwareTex;
begin
  GetTextureHeight := 0;
  if not IsTextureSet(imgHandle) then exit;

  image := GetTexturePtr(imgHandle);
  GetTextureHeight := image^.height
end;

procedure SetTextureHeight(const imgHandle: longint; const value: smallint);
var
  image: PSoftwareTex;
begin
  if not IsTextureSet(imgHandle) then exit;
  if value <= 0 then
    PanicHalt('setImageHeight: Invalid width: ' + I32Str(value));

  image := GetTexturePtr(imgHandle);

  if image^.width * value * 4 > image^.allocSize then
    PanicHalt('setImageHeight: New size exceeds the allocated buffer!');

  image^.height := value
end;


{ Assuming image isn't nil & the bounds are known }
function UnsafeSprPget(const image: PSoftwareTex; const x, y: smallint): longword;
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

function UnsafeSprGetAlpha(const image: PSoftwareTex; const x, y: smallint): byte;
begin
  UnsafeSprGetAlpha := image^.pixelData[
    (x + y * image^.width) * 4 + 3]
end;


procedure UnsafeSprPset(const image: PSoftwareTex; const x, y: smallint; const colour: longword);
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
