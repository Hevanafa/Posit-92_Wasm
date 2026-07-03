unit P92Core;

interface

procedure InitEngine; public name 'InitEngine';


implementation

uses
  WasmMemMgr, InteropBuf, P92AssetRegistry, Timing
{$ifdef UseWebGL}
  , WebGL
{$endif}
  ;

procedure InitEngine;
begin
  InitHeapMgr;
  InitInteropBuffer;
  InitDeltaTime;
  InitAssetRegistry;

{$ifdef UseWebGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}
end;

end.

