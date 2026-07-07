unit P92AssetRegistry;

interface

uses P92BMFont, P92Tex;

const
  MaxTextures = 256;

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
  textures: array[1..MaxTextures] of TSoftwareTexEntry;
  bmfonts: array[1..9] of TBMFontEntry;
  sounds: array[1..255] of TSoundEntry;

  AssetReadyCount,
  AssetTotalCount: longword;

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

function AllAssetsReady: boolean;
begin
  AllAssetsReady := AssetReadyCount >= AssetTotalCount
end;

procedure IncAssetReadyCount;
begin
  inc(AssetReadyCount)
end;

procedure SetAssetReadyCount(value: longint);
begin
  AssetReadyCount := value
end;

procedure SetAssetTotalCount(value: longint);
begin
  AssetTotalCount := value
end;

procedure InitAssetRegistry;
var
  a: word;
begin
  AssetReadyCount := 0;
  AssetTotalCount := 0;

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
  inc(AssetTotalCount);

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

  inc(AssetTotalCount, 2);

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
  inc(AssetTotalCount);

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

  inc(AssetReadyCount);
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

end.
