unit EngineCore;

interface

type
  TAssetStatus = (
    AssetStatusPending,
    AssetStatusLoading,
    AssetStatusReady,
    AssetStatusFailed
  );

var AssetReadyCount, AssetTotalCount: longint;

procedure InitEngine; public name 'InitEngine';

procedure IncAssetReadyCount; public name 'IncAssetReadyCount';
procedure JsRequestImage(imgHandle: longint); external 'env' name 'JsRequestImage';

function RequestImage(const path: string): longint;
procedure PascalImageLoaded(const imgHandle: longint; const w, h: smallint; const pixelData: pointer); public name 'PascalImageLoaded';
procedure PascalImageFailed(const imgHandle: longint; const errorCode: smallint); public name 'PascalImageFailed';


implementation

uses
  WasmMemMgr, ImgRef, InteropBuf, Timing
{$ifdef UseWebGL}
  , WebGL
{$endif}
  ;

procedure InitEngine;
begin
  InitHeapMgr;
  InitInteropBuffer;
  InitDeltaTime;
  InitImgRef;

  AssetReadyCount := 0;
  AssetTotalCount := 0;

{$ifdef UseWebGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}
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

  imgHandle := FindEmptyImageRefSlot;
  WriteInteropString(path);
  JsRequestImage(imgHandle);

  imageRefs[imgHandle] := default(TImageRef);

  RequestImage := imgHandle
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

