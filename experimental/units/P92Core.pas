unit P92Core;

interface

type
  TEngineRunStates = (
    ersBoot,
    ersLoading,
    ersPlaying
  );

var
  engineRunState: TEngineRunStates;

procedure InitEngine; public name 'InitEngine';
procedure InitLoadingState; public name 'InitLoadingState';


implementation

uses
  WasmMemMgr, Logger, InteropBuf, P92AssetRegistry, Timing
{$ifdef UseWebGL}
  , WebGL
{$endif}
  ;

procedure InitEngine;
begin
  engineRunState := ersBoot;

  InitHeapMgr;
  InitInteropBuffer;
  InitDeltaTime;
  InitAssetRegistry;

{$ifdef UseWebGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}
end;

procedure InitLoadingState;
begin
  engineRunState := ersLoading;
  writelog('Entered loading state');
end;

end.

