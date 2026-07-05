unit P92AssetRegistry;

interface

uses P92BMFont, P92Tex;

const
  MaxTextures = 256;

type
  TAssetStatus = (
    AssetStatusPending,
    AssetStatusLoading,
    AssetStatusReady,
    AssetStatusFailed
  );

  TSoftwareTexEntry = record
    texture: TSoftwareTex;
    status: TAssetStatus;
    errorCode: smallint;
  end;

var
  textures: array[1..MaxTextures] of TSoftwareTexEntry;
  AssetReadyCount,
  AssetTotalCount: longword;

function AllAssetsReady: boolean;

{ Temporary fix for legacy procedures that still use a metafile }
procedure IncAssetReadyCount; public name 'IncAssetReadyCount';
procedure SetAssetReadyCount(value: longint); public name 'SetAssetReadyCount';
procedure SetAssetTotalCount(value: longint); public name 'SetAssetTotalCount';

procedure InitAssetRegistry;
function FindUnusedTextureSlot: longint;

procedure JsRequestImage(texHandle: longint); external 'env' name 'JsRequestImage';
function RequestImage(const path: string): longint;

procedure JsRequestBMFont(fontPtr: PBMFont; fontGlyphsPtr: PBMFontGlyph); external 'env' name 'JsRequestBMFont';
procedure RequestBMFont(const path: string; const fontPtr: PBMFont; const fontGlyphsPtr: PBMFontGlyph);

procedure PascalImageLoaded(const texHandle: longint; const w, h: smallint; const pixelData: pointer); public name 'PascalImageLoaded';
procedure PascalImageFailed(const texHandle: longint; const errorCode: smallint); public name 'PascalImageFailed';


implementation

uses P92Conversions, P92InteropBuf, P92Logger, P92Panic;

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
end;

function FindUnusedTextureSlot: longint;
var
  a: longint;
begin
  for a:=1 to high(textures) do
    { if not IsTextureSet(a) then begin }
    if textures[a].status = AssetStatusPending then begin
      FindUnusedTextureSlot := a;
      exit
    end;

  FindUnusedTextureSlot := -1
end;


function RequestImage(const path: string): longint;
var
  texHandle: longint;
begin
  inc(AssetTotalCount);

  texHandle := FindUnusedTextureSlot;
  WriteInteropString(path);
  JsRequestImage(texHandle);

  textures[texHandle] := default(TSoftwareTexEntry);
  textures[texHandle].status := AssetStatusLoading;

  RequestImage := texHandle
end;

procedure RequestBMFont(const path: string; const fontPtr: PBMFont; const fontGlyphsPtr: PBMFontGlyph);
var
  texHandle: longint;
begin
  inc(AssetTotalCount, 2);

  { Reserve the texture handle}
  texHandle := FindUnusedTextureSlot;

  fontptr^.texHandle := texHandle;
  textures[texHandle] := default(TSoftwareTexEntry);
  textures[texHandle].status := AssetStatusLoading;

  WriteInteropString(path);
  JsRequestBMFont(fontPtr, fontGlyphsPtr);
end;

procedure PascalImageLoaded(const texHandle: longint; const w, h: smallint; const pixelData: pointer);
begin
  if (texHandle < 1) or (texHandle >= high(textures)) then
    PanicHalt('Invalid texture handle: ' + I32Str(texHandle));

  if (textures[texHandle].texture.allocSize > 0) then
    PanicHalt('Texture handle ' + I32Str(texHandle) + ' already used! (allocSize > 0)');

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

end.
