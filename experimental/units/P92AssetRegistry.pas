unit P92AssetRegistry;

interface

uses BMFont, SoftwareTex;

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

procedure JsRequestImage(imgHandle: longint); external 'env' name 'JsRequestImage';
function RequestImage(const path: string): longint;

procedure JsRequestBMFont(fontPtr: PBMFont; fontGlyphsPtr: PBMFontGlyph); external 'env' name 'JsRequestBMFont';
procedure RequestBMFont(const path: string; const fontPtr: PBMFont; const fontGlyphsPtr: PBMFontGlyph);

procedure PascalImageLoaded(const imgHandle: longint; const w, h: smallint; const pixelData: pointer); public name 'PascalImageLoaded';
procedure PascalImageFailed(const imgHandle: longint; const errorCode: smallint); public name 'PascalImageFailed';


implementation

uses P92Conversions, InteropBuf, P92Logger, P92Panic;

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
  imgHandle: longint;
begin
  inc(AssetTotalCount);

  imgHandle := FindUnusedTextureSlot;
  WriteInteropString(path);
  JsRequestImage(imgHandle);

  textures[imgHandle] := default(TSoftwareTexEntry);
  textures[imgHandle].status := AssetStatusLoading;

  RequestImage := imgHandle
end;

procedure RequestBMFont(const path: string; const fontPtr: PBMFont; const fontGlyphsPtr: PBMFontGlyph);
var
  imgHandle: longint;
begin
  inc(AssetTotalCount, 2);

  imgHandle := FindUnusedTextureSlot;

  fontptr^.imgHandle := imgHandle;
  textures[imgHandle] := default(TSoftwareTexEntry);
  textures[imgHandle].status := AssetStatusLoading;

  WriteInteropString(path);
  JsRequestBMFont(fontPtr, fontGlyphsPtr);
end;

procedure PascalImageLoaded(const imgHandle: longint; const w, h: smallint; const pixelData: pointer);
begin
  if (imgHandle < 1) or (imgHandle >= high(textures)) then
    PanicHalt('Invalid image handle: ' + I32Str(imgHandle));

  if (textures[imgHandle].texture.allocSize > 0) then
    PanicHalt('Image handle ' + I32Str(imgHandle) + ' already used! (allocSize > 0)');

  textures[imgHandle].texture.width := w;
  textures[imgHandle].texture.height := h;
  textures[imgHandle].texture.allocSize := w * h * 4;
  textures[imgHandle].texture.pixelData := pixelData;

  textures[imgHandle].status := AssetStatusReady;
  textures[imgHandle].errorCode := 0;

  inc(AssetReadyCount);
end;

procedure PascalImageFailed(const imgHandle: longint; const errorCode: smallint);
begin
  textures[imgHandle].status := AssetStatusFailed;
  textures[imgHandle].errorCode := errorCode;
end;

end.
