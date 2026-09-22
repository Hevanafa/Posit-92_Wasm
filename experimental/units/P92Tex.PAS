{
  Base texture unit - Part of Posit-92 game engine
  Hevanafa

  Base unit for SoftwareTexDraw and ImgRefComp
  Most of the procedures & functions here are based on Bitmap and SprFast units
  
  The term "texture" used in this unit is strictly in the context of CPU rendering
}

unit P92Tex;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }
{$B-}  { Enable boolean short-circuiting }
{$R-}  { Turn off range checks }
{$Q-}  { Turn off overflow checks }

{$Notes OFF}
{$Inline ON}
{Define PanicOnInvalidHandle}

interface

uses P92AssetHandles;

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


function NewTex(const width, height: smallint): TTextureHandle;
function CopyTex(const texHandle: TTextureHandle): TTextureHandle;
procedure FreeTex(const texHandle: TTextureHandle);

function IsTexSet(const texHandle: TTextureHandle): boolean;
procedure AssertTexSet(const varName: string; const texHandle: longint);
function BorrowTexPtr(const texHandle: TTextureHandle): PSoftwareTex;

function GetTexWidth(const texHandle: TTextureHandle): smallint;
procedure SetTexWidth(const texHandle: TTextureHandle; const value: smallint);
function GetTexHeight(const texHandle: TTextureHandle): smallint;
procedure SetTexHeight(const texHandle: TTextureHandle; const value: smallint);

{ Assuming the texture isn't nil & the bounds are known
  return colour: ABGR }
function UnsafeSprPGet(const texture: PSoftwareTex; const x, y: smallint): longword;
function UnsafeSprGetAlpha(const texture: PSoftwareTex; const x, y: smallint): byte;

procedure UnsafeSprPSet(const texture: PSoftwareTex; const x, y: smallint; const ABGR: longword);


implementation

uses
  P92Conversions, P92Logger, P92Maths, P92Panic, P92AssetRegistry,
{$ifdef P92_WASM}
  P92WasmHeap,
{$endif}
  P92VGA;

function NewTex(const width, height: smallint): TTextureHandle;
var
  handle: TTextureHandle;
  allocSize: longword;
  dataPtr: PByte;
begin
  if width <= 0 then
    PanicHalt('NewTexture: Invalid width: ' + I32Str(width));

  if height <= 0 then
    PanicHalt('NewTexture: Invalid height: ' + I32Str(height));

  handle := FindUnusedTextureHandle;

  if handle < 0 then PanicHalt('Software texture pool is full!');
  
  allocSize := width * height * 4;
  dataPtr := PByte(getmem(allocSize));
  FillChar(dataPtr^, allocSize, 0);

  textures[handle].texture.width := width;
  textures[handle].texture.height := height;
  textures[handle].texture.allocSize := allocSize;
  textures[handle].texture.pixelData := dataPtr;

  textures[handle].status := AssetStatusReady;
  textures[handle].errorCode := 0;

  NewTex := handle
end;

{
  Makes a copy of the source texture
  Returns: a new texture handle
}
function CopyTex(const texHandle: TTextureHandle): TTextureHandle;
var
  newHandle: TTextureHandle;
  src, dest: PSoftwareTex;
begin
  src := @textures[texHandle].texture;
  newHandle := NewTex(src^.width, src^.height);
  dest := @textures[newHandle].texture;

  move(src^.pixelData^, dest^.pixelData^, src^.allocSize);
  CopyTex := newHandle
end;

procedure FreeTex(const texHandle: TTextureHandle);
begin
  if (texHandle < low(textures)) or (texHandle >= high(textures)) then exit;
  if textures[texHandle].texture.pixelData = nil then exit;

{$ifdef P92_WASM}
  WasmFreeMem(textures[texHandle].texture.pixelData);
{$endif}
{$ifdef P92_SDL2}
  FreeMem(textures[texHandle].texture.pixelData);
{$endif}

  textures[texHandle].status := AssetStatusEmpty;
  textures[texHandle].errorCode := 0;

  textures[texHandle].texture.width := 0;
  textures[texHandle].texture.height := 0;
  textures[texHandle].texture.allocSize := 0;
  textures[texHandle].texture.pixelData := nil
end;


function IsTexSet(const texHandle: TTextureHandle): boolean;
begin
  IsTexSet := false;

{$ifdef PanicOnInvalidHandle}
  if imgHandle <= 0 then
    panicHalt('Invalid imgHandle: ' + i32str(imgHandle));
{$else}
  if texHandle <= 0 then exit;
{$endif}

  { IsTexSet := (textures[texHandle].width > 0) and (textures[texHandle].height > 0) }
  { IsTexSet := (textures[texHandle].allocSize > 0) }
  IsTexSet := textures[texHandle].status = AssetStatusReady
end;

procedure AssertTexSet(const varName: string; const texHandle: longint);
begin
  if not IsTexSet(texHandle) then
    PanicHalt(varName + ' is unset!');
end;

function BorrowTexPtr(const texHandle: TTextureHandle): PSoftwareTex;
begin
  BorrowTexPtr := @textures[texHandle].texture
end;

function GetTexWidth(const texHandle: TTextureHandle): smallint;
var
  texture: PSoftwareTex;
begin
  GetTexWidth := 0;
  if not IsTexSet(texHandle) then exit;

  texture := @textures[texHandle].texture;
  GetTexWidth := texture^.width
end;

procedure SetTexWidth(const texHandle: TTextureHandle; const value: smallint);
var
  texture: PSoftwareTex;
begin
  if not IsTexSet(texHandle) then exit;

  if value <= 0 then
    PanicHalt('SetTextureWidth: Invalid width: ' + I32Str(value));

  texture := @textures[texHandle].texture;

  if value * texture^.height * 4 > texture^.allocSize then
    PanicHalt('SetTextureWidth: New size exceeds the allocated buffer!');

  texture^.width := value
end;


function GetTexHeight(const texHandle: TTextureHandle): smallint;
var
  texture: PSoftwareTex;
begin
  GetTexHeight := 0;
  if not IsTexSet(texHandle) then exit;

  texture := @textures[texHandle].texture;
  GetTexHeight := texture^.height
end;

procedure SetTexHeight(const texHandle: TTextureHandle; const value: smallint);
var
  texture: PSoftwareTex;
begin
  if not IsTexSet(texHandle) then exit;

  if value <= 0 then
    PanicHalt('SetTextureHeight: Invalid height: ' + I32Str(value));

  texture := @textures[texHandle].texture;

  if texture^.width * value * 4 > texture^.allocSize then
    PanicHalt('SetTextureHeight: New size exceeds the allocated buffer!');

  texture^.height := value
end;

function UnsafeSprPGet(const texture: PSoftwareTex; const x, y: smallint): longword; inline;
var
  offset: longword;
begin
  offset := (x + y * texture^.width) * 4;
  UnsafeSprPGet := PLongWord(@texture^.pixelData[offset])^
end;

function UnsafeSprGetAlpha(const texture: PSoftwareTex; const x, y: smallint): byte;
begin
  UnsafeSprGetAlpha := texture^.pixelData[
    (x + y * texture^.width) * 4 + 3]
end;


procedure UnsafeSprPSet(const texture: PSoftwareTex; const x, y: smallint; const ABGR: longword);
var
  offset: longword;
begin
  offset := (x + y * texture^.width) * 4;
  PLongWord(@texture^.pixelData[offset])^ := ABGR
end;

end.
