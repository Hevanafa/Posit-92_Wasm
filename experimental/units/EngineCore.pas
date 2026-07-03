unit EngineCore;

interface

procedure InitEngine; public name 'InitEngine';

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

{$ifdef UseWebGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}
end;

function RequestImage(const path: string): longint;
var
  imgHandle: longint;
begin
  imgHandle := FindEmptyImageRefSlot;
  WriteInteropString(path);
  JsRequestImage(imgHandle);

  RequestImage := imgHandle
end;

end.

