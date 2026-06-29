unit EngineCore;

interface

procedure InitEngine; public name 'InitEngine';


implementation

uses
  WasmMemMgr, InteropBuf, Timing
{$ifdef UseWebGL}
  , WebGL
{$endif};

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

end.

