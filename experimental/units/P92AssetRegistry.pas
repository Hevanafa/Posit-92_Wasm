unit P92AssetRegistry;

interface

uses BMFont;

type
  TAssetStatus = (
    AssetStatusPending,
    AssetStatusLoading,
    AssetStatusReady,
    AssetStatusFailed
  );

var
  AssetReadyCount,
  AssetTotalCount: longword;

procedure IncAssetReadyCount; public name 'IncAssetReadyCount';

procedure JsRequestImage(imgHandle: longint); external 'env' name 'JsRequestImage';
function RequestImage(const path: string): longint;
procedure RegisterSoftwareTex(const imgHandle: longint; const dataPtr: PByte; const w, h: smallint); public name 'RegisterSoftwareTex';

procedure JsRequestBMFont(fontPtr: PBMFont; fontGlyphsPtr: PBMFontGlyph); external 'env' name 'JsRequestBMFont';
procedure RequestBMFont(const path: string; const fontPtr: PBMFont; const fontGlyphsPtr: PBMFontGlyph);

procedure PascalImageLoaded(const imgHandle: longint; const w, h: smallint; const pixelData: pointer); public name 'PascalImageLoaded';
procedure PascalImageFailed(const imgHandle: longint; const errorCode: smallint); public name 'PascalImageFailed';


implementation

uses Conv, SoftwareTex, InteropBuf, Panic;

procedure RegisterSoftwareTex(const imgHandle: longint; const dataPtr: PByte; const w, h: smallint);
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

  imageRefs[imgHandle] := default(TSoftwareTex);
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
  imageRefs[imgHandle].width := w;
  imageRefs[imgHandle].height := h;
  imageRefs[imgHandle].allocSize := w * h * 4;
  imageRefs[imgHandle].pixelData := pixelData;

  imageRefs[imgHandle].status := AssetStatusReady;
  imageRefs[imgHandle].errorCode := 0
end;

procedure PascalImageFailed(const imgHandle: longint; const errorCode: smallint);
begin
  imageRefs[imgHandle].status := AssetStatusFailed;
  imageRefs[imgHandle].errorCode := errorCode;
end;

end.
