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

procedure JsRequestBMFont(fontPtr: PBMFont; fontGlyphsPtr: PBMFontGlyph); external 'env' name 'JsRequestBMFont';
procedure RequestBMFont(const path: string; const fontPtr: PBMFont; const fontGlyphsPtr: PBMFontGlyph);

procedure PascalImageLoaded(const imgHandle: longint; const w, h: smallint; const pixelData: pointer); public name 'PascalImageLoaded';
procedure PascalImageFailed(const imgHandle: longint; const errorCode: smallint); public name 'PascalImageFailed';


implementation

uses ImgRef, InteropBuf;

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
