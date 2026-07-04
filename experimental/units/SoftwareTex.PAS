{
  SoftwareTex unit - Part of Posit-92 game engine
  Hevanafa

  Base unit for SoftwareTexDraw and ImgRefComp
  Most of the procedures & functions here are based on Bitmap and SprFast units
  
  The term "texture" used in this unit is strictly in the context of software rendering
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

type
  PSoftwareTex = ^TSoftwareTex;
  TSoftwareTex = record
    width: smallint;
    height: smallint;
    allocSize: longword;
    pixelData: PByte;
  end;

const
  { SprFlips enum }
  SprFlipNone = 0;
  SprFlipHorizontal = 1;
  SprFlipVertical = 2;
  SprFlipBoth = SprFlipHorizontal or SprFlipVertical;

function NewTexture(const width, height: smallint): longint;
function CopyTexture(const texHandle: longint): longint;
procedure FreeTexture(const texHandle: longint);

function IsTextureSet(const texHandle: longint): boolean;
procedure AssertTextureSet(const varName: string; const texHandle: longint);
function GetTexturePtr(const texHandle: longint): PSoftwareTex;

function GetTextureWidth(const texHandle: longint): smallint;
procedure SetTextureWidth(const texHandle: longint; const value: smallint);
function GetTextureHeight(const texHandle: longint): smallint;
procedure SetTextureHeight(const texHandle: longint; const value: smallint);

function UnsafeSprPget(const texture: PSoftwareTex; const x, y: smallint): longword;
function UnsafeSprGetAlpha(const texture: PSoftwareTex; const x, y: smallint): byte;
procedure UnsafeSprPset(const texture: PSoftwareTex; const x, y: smallint; const colour: longword);


implementation

uses
  Conv, P92Logger, P92Maths, P92Panic, P92AssetRegistry,
{$ifdef WASM}
  WasmHeap,
{$endif}
{$ifdef Windows}
{$endif}
  VGA;

function NewTexture(const width, height: smallint): longint;
var
  slot: longint;
  allocSize: longword;
  dataPtr: PByte;
begin
  if width <= 0 then
    PanicHalt('NewTexture: Invalid width: ' + I32Str(width));

  if height <= 0 then
    PanicHalt('NewTexture: Invalid height: ' + I32Str(height));

  slot := FindUnusedTextureSlot;
  if slot < 0 then PanicHalt('Software texture pool is full!');
  
  allocSize := width * height * 4;
  dataPtr := PByte(getmem(allocSize));
  fillchar(dataPtr^, allocSize, 0);

  textures[slot].texture.width := width;
  textures[slot].texture.height := height;
  textures[slot].texture.allocSize := allocSize;
  textures[slot].texture.pixelData := dataPtr;

  textures[slot].status := AssetStatusReady;
  textures[slot].errorCode := 0;

  NewTexture := slot
end;

{
  Makes a copy of the source texture
  Returns: a new texture handle
}
function CopyTexture(const texHandle: longint): longint;
var
  slot: longint;
  src, dest: PSoftwareTex;
begin
  src := GetTexturePtr(texHandle);
  slot := NewTexture(src^.width, src^.height);
  dest := GetTexturePtr(slot);

  move(src^.pixelData^, dest^.pixelData^, src^.allocSize);
  CopyTexture := slot
end;

procedure FreeTexture(const texHandle: longint);
begin
  if (texHandle < 1) or (texHandle >= MaxTextures) then exit;
  if textures[texHandle].texture.pixelData = nil then exit;

{$ifdef WASM}
  WasmFreeMem(textures[texHandle].texture.pixelData);
{$endif}
{$ifdef Windows}
  FreeMem(imageRefs[imgHandle].dataPtr);
{$endif}

  textures[texHandle].texture.width := 0;
  textures[texHandle].texture.height := 0;
  textures[texHandle].texture.allocSize := 0;
  textures[texHandle].texture.pixelData := nil
end;


function IsTextureSet(const texHandle: longint): boolean;
begin
  IsTextureSet := false;

{$ifdef PanicOnInvalidHandle}
  if imgHandle <= 0 then
    panicHalt('Invalid imgHandle: ' + i32str(imgHandle));
{$else}
  if texHandle <= 0 then exit;
{$endif}

  { IsTextureSet := (textures[texHandle].width > 0) and (textures[texHandle].height > 0) }
  { IsTextureSet := (textures[texHandle].allocSize > 0) }
  IsTextureSet := textures[texHandle].status = AssetStatusReady
end;

procedure AssertTextureSet(const varName: string; const texHandle: longint);
begin
  if not IsTextureSet(texHandle) then
    PanicHalt(varName + ' is unset!');
end;

function GetTexturePtr(const texHandle: longint): PSoftwareTex;
begin
  GetTexturePtr := @textures[texHandle]
end;


function GetTextureWidth(const texHandle: longint): smallint;
var
  texture: PSoftwareTex;
begin
  GetTextureWidth := 0;
  if not IsTextureSet(texHandle) then exit;

  texture := GetTexturePtr(texHandle);
  GetTextureWidth := texture^.width
end;

procedure SetTextureWidth(const texHandle: longint; const value: smallint);
var
  texture: PSoftwareTex;
begin
  if not IsTextureSet(texHandle) then exit;

  if value <= 0 then
    PanicHalt('SetTextureWidth: Invalid width: ' + I32Str(value));

  texture := GetTexturePtr(texHandle);

  if value * texture^.height * 4 > texture^.allocSize then
    PanicHalt('SetTextureWidth: New size exceeds the allocated buffer!');

  texture^.width := value
end;


function GetTextureHeight(const texHandle: longint): smallint;
var
  texture: PSoftwareTex;
begin
  GetTextureHeight := 0;
  if not IsTextureSet(texHandle) then exit;

  texture := GetTexturePtr(texHandle);
  GetTextureHeight := texture^.height
end;

procedure SetTextureHeight(const texHandle: longint; const value: smallint);
var
  texture: PSoftwareTex;
begin
  if not IsTextureSet(texHandle) then exit;

  if value <= 0 then
    PanicHalt('SetTextureHeight: Invalid height: ' + I32Str(value));

  texture := GetTexturePtr(texHandle);

  if texture^.width * value * 4 > texture^.allocSize then
    PanicHalt('SetTextureHeight: New size exceeds the allocated buffer!');

  texture^.height := value
end;


{ Assuming the texture isn't nil & the bounds are known }
function UnsafeSprPget(const texture: PSoftwareTex; const x, y: smallint): longword;
var
  offset: longword;
begin
  offset := (x + y * texture^.width) * 4;

  UnsafeSprPget :=
    (texture^.pixelData[offset + 3] shl 24)
    or (texture^.pixelData[offset] shl 16)
    or (texture^.pixelData[offset + 1] shl 8)
    or texture^.pixelData[offset + 2]
end;

function UnsafeSprGetAlpha(const texture: PSoftwareTex; const x, y: smallint): byte;
begin
  UnsafeSprGetAlpha := texture^.pixelData[
    (x + y * texture^.width) * 4 + 3]
end;


procedure UnsafeSprPset(const texture: PSoftwareTex; const x, y: smallint; const colour: longword);
var
  offset: longword;
begin
  offset := (x + y * texture^.width) * 4;

  { Order: RGBA }
  texture^.pixelData[offset] := colour shr 16 and $FF;
  texture^.pixelData[offset + 1] := colour shr 8 and $FF;
  texture^.pixelData[offset + 2] := colour and $FF;
  texture^.pixelData[offset + 3] := colour shr 24 and $FF;
end;

end.
