unit P92Core;

interface

procedure InitEngine; public name 'InitEngine';


implementation

uses
  WasmMemMgr, SoftwareTex, InteropBuf, P92AssetRegistry, Timing
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

  AssetReadyCount := 0;
  AssetTotalCount := 0;

{$ifdef UseWebGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}
end;

end.

