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

  TBMFontLegacyEntry = record
    fontPtr: PBMFontLegacy;
    glyphsPtr: PBMFontGlyph;
    status: TAssetStatus;
    errorCode: smallint;
  end;

  TBMFontEntry = record
    fontPtr: PBMFont;
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

procedure JsRequestBMFontLegacy(bmfontHandle: longint; fontPtr: PBMFontLegacy; fontGlyphsPtr: PBMFontGlyph); external 'env' name 'JsRequestBMFont';
procedure RequestBMFontLegacy(const path: string; const fontPtr: PBMFontLegacy; const fontGlyphsPtr: PBMFontGlyph);

procedure JsRequestBMFont; external 'env' name 'JsRequestBMFont';
procedure RequestBMFont(const path: string);

function GetBMFontBufferPtr: pointer; public name 'GetBMFontBufferPtr';
function GetBMFontBufferLen: smallint; public name 'GetBMFontBufferLen';
procedure SetBMFontBufferLen(value: smallint); public name 'SetBMFontBufferLen';

procedure JsRequestSound(sndHandle: longint); external 'env' name 'JsRequestSound';
function RequestSound(const path: string): longint;

{ Reporting procedures }

procedure PascalImageLoaded(texHandle: longint; w, h: smallint; pixelData: pointer); public name 'PascalImageLoaded';
procedure PascalImageFailed(texHandle: longint; errorCode: smallint); public name 'PascalImageFailed';

procedure PascalBMFontLoaded(bmfontHandle: longint); public name 'PascalBMFontLoaded';
procedure PascalBMFontFailed(bmfontHandle: longint; errorCode: smallint); public name 'PascalBMFontFailed';

procedure PascalSoundLoaded(sndHandle: longint); public name 'PascalSoundLoaded';
procedure PascalSoundFailed(sndHandle: longint; errorCode: smallint); public name 'PascalSoundFailed';


implementation

uses
  P92Conversions, P92InteropBuf, P92Logger, P92Panic;

var
  bmfonts: array[1..9] of TBMFontLegacyEntry;
  sounds: array[1..255] of TSoundEntry;

  assetReadyCount, assetTotalCount: longword;

  bmfontBuffer: array[0..32767] of byte;
  bmfontBufferLen: smallint;

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

  for a:=1 to high(textures) do
    textures[a] := default(TSoftwareTexEntry);

  for a:=1 to high(bmfonts) do
    bmfonts[a] := default(TBMFontLegacyEntry);

  for a:=1 to high(sounds) do
    sounds[a] := default(TSoundEntry);

  fillchar(bmfontBuffer, sizeof(bmfontBuffer), 0);
  bmfontBufferLen := 0;
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
  WriteLog('RequestImage: inc assetTotalCount');

  texHandle := FindUnusedTextureSlot;
  textures[texHandle] := default(TSoftwareTexEntry);
  textures[texHandle].status := AssetStatusLoading;

  WriteInteropString(path);
  JsRequestImage(texHandle);

  RequestImage := texHandle
end;


procedure RequestBMFont(const path: string);
begin
  WriteInteropString(path);
  JsRequestBMFont;
  inc(assetTotalCount)
end;

procedure RequestBMFontLegacy(const path: string; const fontPtr: PBMFontLegacy; const fontGlyphsPtr: PBMFontGlyph);
var
  bmfontHandle: longint;
begin
  bmfontHandle := FindUnusedBMFontSlot;

  if bmfontHandle < 0 then
    PanicHalt('RequestBMFont: BMFont slots are full!');

  bmfonts[bmfontHandle] := default(TBMFontLegacyEntry);
  bmfonts[bmfontHandle].fontPtr := fontPtr;
  bmfonts[bmfontHandle].glyphsPtr := fontGlyphsPtr;
  bmfonts[bmfontHandle].status := AssetStatusLoading;

  inc(assetTotalCount);
  WriteLog('RequestBMFont: inc assetTotalCount');

  { Reserve the texture handle}
  {
  texHandle := FindUnusedTextureSlot;

  fontptr^.texHandle := texHandle;
  textures[texHandle] := default(TSoftwareTexEntry);
  textures[texHandle].status := AssetStatusLoading;
  }

  WriteInteropString(path);
  JsRequestBMFontLegacy(bmfontHandle, fontPtr, fontGlyphsPtr);
end;

function GetBMFontBufferPtr: pointer;
begin
  GetBMFontBufferPtr := @bmfontBuffer[0]
end;

function GetBMFontBufferLen: smallint;
begin
  GetBMFontBufferLen := bmfontBufferLen
end;

procedure SetBMFontBufferLen(value: smallint);
begin
  bmfontBufferLen := value
end;

function RequestSound(const path: string): longint;
var
  sndHandle: longint;
begin
  inc(assetTotalCount);
  WriteLog('RequestSound: inc assetTotalCount');

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

procedure PascalImageLoaded(texHandle: longint; w, h: smallint; pixelData: pointer);
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
  WriteLog('Image: inc assetReadyCount');
end;

procedure PascalImageFailed(texHandle: longint; errorCode: smallint);
begin
  textures[texHandle].status := AssetStatusFailed;
  textures[texHandle].errorCode := errorCode;
end;

procedure PascalBMFontLoaded(bmfontHandle: longint);
begin
  bmfonts[bmfontHandle].status := AssetStatusReady;
  bmfonts[bmfontHandle].errorCode := 0;

  bmfonts[bmfontHandle].fontPtr^.texHandle :=
    RequestImage(ReadInteropString); { bmfonts[bmfontHandle].fontPtr^.filename }

  inc(assetReadyCount);
  WriteLog('BMFont: inc assetReadyCount');
end;

procedure PascalBMFontFailed(bmfontHandle: longint; errorCode: smallint);
begin
  bmfonts[bmfontHandle].status := AssetStatusFailed;
  bmfonts[bmfontHandle].errorCode := errorCode
end;

procedure PascalSoundLoaded(sndHandle: longint);
begin
  sounds[sndHandle].status := AssetStatusReady;
  sounds[sndHandle].errorCode := 0;

  inc(assetReadyCount);
  WriteLog('Sound: inc assetReadyCount');
end;

procedure PascalSoundFailed(sndHandle: longint; errorCode: smallint);
begin
  sounds[sndHandle].status := AssetStatusFailed;
  sounds[sndHandle].errorCode := errorCode
end;

end.
