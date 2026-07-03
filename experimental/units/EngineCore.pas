unit EngineCore;

interface

var AssetReadyCount, AssetTotalCount: longint;

procedure InitEngine; public name 'InitEngine';

procedure IncAssetReadyCount; public name 'IncAssetReadyCount';
procedure JsRequestImage(imgHandle: longint); external 'env' name 'JsRequestImage';
function RequestImage(const path: string): longint;

implementation

uses
  WasmMemMgr, InteropBuf, Timing, ImgRef
{$ifdef UseWebGL}
  , WebGL
{$endif}
  ;

procedure InitEngine;
begin
  InitHeapMgr;
  InitInteropBuffer;
  InitDeltaTime;

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

  RequestImage := imgHandle
end;

end.

