unit P92AssetRegistry;

interface

uses P92BMFont, P92Tex;

type
  TAssetStatus = (
    AssetStatusEmpty,
    AssetStatusLoading,
    AssetStatusReady,
    AssetStatusFailed
  );

  TSoftwareTexEntry = record
    texture: TSoftwareTex;
    status: TAssetStatus;
    errorCode: smallint;
  end;

  TBMFontEntry = record
    fontPtr: PBMFont;
    glyphsPtr: PBMFontGlyph;
    status: TAssetStatus;
    errorCode: smallint;
  end;

  TSoundEntry = record
    status: TAssetStatus;
    errorCode: smallint;
  end;

var
  textures: array[1..255] of TSoftwareTexEntry;

function GetAssetReadyCount: longword;
function GetAssetTotalCount: longword;
function AllAssetsReady: boolean;

procedure InitAssetRegistry;
function FindUnusedTextureSlot: longint;

procedure JsRequestImage(texHandle: longint); external 'env' name 'JsRequestImage';
function RequestImage(const path: string): longint;

procedure JsRequestBMFont(bmfontHandle: longint; fontPtr: PBMFont; fontGlyphsPtr: PBMFontGlyph); external 'env' name 'JsRequestBMFont';
procedure RequestBMFont(const path: string; const fontPtr: PBMFont; const fontGlyphsPtr: PBMFontGlyph);

procedure JsRequestSound(sndHandle: longint); external 'env' name 'JsRequestSound';
function RequestSound(const path: string): longint;

{ Reporting procedures }

procedure PascalImageLoaded(const texHandle: longint; const w, h: smallint; const pixelData: pointer); public name 'PascalImageLoaded';
procedure PascalImageFailed(const texHandle: longint; const errorCode: smallint); public name 'PascalImageFailed';

procedure PascalBMFontLoaded(const bmfontHandle: longint); public name 'PascalBMFontLoaded';
procedure PascalBMFontFailed(const bmfontHandle: longint; const errorCode: smallint); public name 'PascalBMFontFailed';

implementation

uses
  P92Conversions, P92InteropBuf, P92Logger, P92Panic;

var
  bmfonts: array[1..9] of TBMFontEntry;
  sounds: array[1..255] of TSoundEntry;

  assetReadyCount,
  assetTotalCount: longword;

function GetAssetReadyCount: longword;
begin
  GetAssetReadyCount := assetReadyCount
end;

function GetAssetTotalCount: longword;
begin
  GetAssetTotalCount := assetTotalCount
end;

function AllAssetsReady: boolean;
begin
  AllAssetsReady := assetReadyCount >= assetTotalCount
end;

procedure IncAssetReadyCount;
begin
  inc(assetReadyCount)
end;

procedure SetAssetReadyCount(value: longint);
begin
  assetReadyCount := value
end;

procedure SetAssetTotalCount(value: longint);
begin
  assetTotalCount := value
end;

procedure InitAssetRegistry;
var
  a: word;
begin
  assetReadyCount := 0;
  assetTotalCount := 0;

  for a := 1 to high(textures) do
    textures[a] := default(TSoftwareTexEntry);

  for a:=1 to high(bmfonts) do
    bmfonts[a] := default(TBMFontEntry);
end;

function FindUnusedTextureSlot: longint;
var
  a: longint;
begin
  for a:=1 to high(textures) do
    if textures[a].status = AssetStatusEmpty then begin
      FindUnusedTextureSlot := a;
      exit
    end;

  FindUnusedTextureSlot := -1
end;

function FindUnusedBMFontSlot: longint;
var
  a: longint;
begin
  for a:=1 to high(bmfonts) do
    if bmfonts[a].status = AssetStatusEmpty then begin
      FindUnusedBMFontSlot := a;
      exit
    end;

  FindUnusedBMFontSlot := -1
end;

function FindUnusedSoundSlot: longint;
var
  a: longint;
begin
  for a:=1 to high(sounds) do
    if sounds[a].status = AssetStatusEmpty then begin
      FindUnusedSoundSlot := a;
      exit
    end;

  FindUnusedSoundSlot := -1
end;

function RequestImage(const path: string): longint;
var
  texHandle: longint;
begin
  inc(assetTotalCount);

  texHandle := FindUnusedTextureSlot;
  textures[texHandle] := default(TSoftwareTexEntry);
  textures[texHandle].status := AssetStatusLoading;

  WriteInteropString(path);
  JsRequestImage(texHandle);

  RequestImage := texHandle
end;

procedure RequestBMFont(const path: string; const fontPtr: PBMFont; const fontGlyphsPtr: PBMFontGlyph);
var
  bmfontHandle: longint;
  texHandle: longint;
begin
  bmfontHandle := FindUnusedBMFontSlot;

  if bmfontHandle < 0 then
    PanicHalt('RequestBMFont: BMFont slots are full!');

  bmfonts[bmfontHandle] := default(TBMFontEntry);
  bmfonts[bmfontHandle].status := AssetStatusLoading;

  inc(assetTotalCount, 2);

  { Reserve the texture handle}
  texHandle := FindUnusedTextureSlot;

  fontptr^.texHandle := texHandle;
  textures[texHandle] := default(TSoftwareTexEntry);
  textures[texHandle].status := AssetStatusLoading;

  WriteInteropString(path);
  JsRequestBMFont(bmfontHandle, fontPtr, fontGlyphsPtr);
end;

function RequestSound(const path: string): longint;
var
  sndHandle: longint;
begin
  inc(assetTotalCount);

  sndHandle := FindUnusedSoundSlot;

  if sndHandle < 0 then
    PanicHalt('RequestSound: Sound slots are full!');

  sounds[sndHandle] := default(TSoundEntry);
  sounds[sndHandle].status := AssetStatusLoading;

  WriteInteropString(path);
  JsRequestSound(sndHandle);

  RequestSound := sndHandle
end;

{ Report asset state to Pascal }

procedure PascalImageLoaded(const texHandle: longint; const w, h: smallint; const pixelData: pointer);
begin
  if (texHandle < 1) or (texHandle >= high(textures)) then
    PanicHalt('Invalid texture handle: ' + I32Str(texHandle));

  textures[texHandle].texture.width := w;
  textures[texHandle].texture.height := h;
  textures[texHandle].texture.allocSize := w * h * 4;
  textures[texHandle].texture.pixelData := pixelData;

  textures[texHandle].status := AssetStatusReady;
  textures[texHandle].errorCode := 0;

  inc(assetReadyCount);
end;

procedure PascalImageFailed(const texHandle: longint; const errorCode: smallint);
begin
  textures[texHandle].status := AssetStatusFailed;
  textures[texHandle].errorCode := errorCode;
end;

procedure PascalBMFontLoaded(const bmfontHandle: longint);
begin
  bmfonts[bmfontHandle].status := AssetStatusReady;
  bmfonts[bmfontHandle].errorCode := 0
end;

procedure PascalBMFontFailed(const bmfontHandle: longint; const errorCode: smallint);
begin
  bmfonts[bmfontHandle].status := AssetStatusFailed;
  bmfonts[bmfontHandle].errorCode := errorCode
end;

procedure PascalSoundLoaded(const sndHandle: longint);
begin
  sounds[sndHandle].status := AssetStatusReady;
  sounds[sndHandle].errorCode := 0
end;

procedure PascalSoundFailed(const sndHandle: longint; const errorCode: smallint);
begin
  sounds[sndHandle].status := AssetStatusFailed;
  sounds[sndHandle].errorCode := errorCode
end;

end.
