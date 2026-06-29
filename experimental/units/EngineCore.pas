unit EngineCore;

interface

procedure InitEngine;


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

