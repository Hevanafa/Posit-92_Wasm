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

  TSoftwareTexRef = record
    texture: TSoftwareTex;
    status: TAssetStatus;
    errorCode: smallint;
  end;

var
  imageRefs: array[1..MaxTextures] of TSoftwareTexRef;
  AssetReadyCount,
  AssetTotalCount: longword;

procedure InitAssetRegistry;
function FindUnusedTextureSlot: longint;

procedure IncAssetReadyCount; public name 'IncAssetReadyCount';

procedure JsRequestImage(imgHandle: longint); external 'env' name 'JsRequestImage';
function RequestImage(const path: string): longint;

procedure JsRequestBMFont(fontPtr: PBMFont; fontGlyphsPtr: PBMFontGlyph); external 'env' name 'JsRequestBMFont';
procedure RequestBMFont(const path: string; const fontPtr: PBMFont; const fontGlyphsPtr: PBMFontGlyph);

procedure PascalImageLoaded(const imgHandle: longint; const w, h: smallint; const pixelData: pointer); public name 'PascalImageLoaded';
procedure PascalImageFailed(const imgHandle: longint; const errorCode: smallint); public name 'PascalImageFailed';


implementation

uses Conv, InteropBuf, Panic;

procedure InitAssetRegistry;
var
  a: word;
begin
  for a := 1 to high(imageRefs) do
    imageRefs[a] := default(TSoftwareTexRef);
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


procedure IncAssetReadyCount;
begin
  inc(AssetReadyCount)
end;

function RequestImage(const path: string): longint;
var
  imgHandle: longint;
begin
  inc(AssetTotalCount);

  imgHandle := FindUnusedTextureSlot;
  WriteInteropString(path);
  JsRequestImage(imgHandle);

  imageRefs[imgHandle] := default(TSoftwareTexRef);
  imageRefs[imgHandle].status := AssetStatusLoading;

  RequestImage := imgHandle
end;

procedure RequestBMFont(const path: string; const fontPtr: PBMFont; const fontGlyphsPtr: PBMFontGlyph);
begin
  WriteInteropString(path);
  JsRequestBMFont(fontPtr, fontGlyphsPtr)
end;

procedure PascalImageLoaded(const imgHandle: longint; const w, h: smallint; const pixelData: pointer);
begin
  if (imgHandle < 1) or (imgHandle >= high(imageRefs)) then
    PanicHalt('Invalid image handle: ' + I32Str(imgHandle));

  if (imageRefs[imgHandle].texture.allocSize > 0) then
    PanicHalt('Image handle ' + I32Str(imgHandle) + ' already used! (allocSize > 0)');

  imageRefs[imgHandle].texture.width := w;
  imageRefs[imgHandle].texture.height := h;
  imageRefs[imgHandle].texture.allocSize := w * h * 4;
  imageRefs[imgHandle].texture.pixelData := pixelData;

  imageRefs[imgHandle].status := AssetStatusReady;
  imageRefs[imgHandle].errorCode := 0
end;

procedure PascalImageFailed(const imgHandle: longint; const errorCode: smallint);
begin
  imageRefs[imgHandle].status := AssetStatusFailed;
  imageRefs[imgHandle].errorCode := errorCode;
end;

end.
