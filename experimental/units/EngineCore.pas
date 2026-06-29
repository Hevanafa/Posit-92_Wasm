unit EngineCore;

interface

procedure InitEngine; public name 'InitEngine';


implementation

uses
  WasmMemMgr, InteropBuf, Timing;

procedure InitEngine;
begin
  InitHeapMgr;
  InitInteropBuffer;
  InitDeltaTime
end;

end.

