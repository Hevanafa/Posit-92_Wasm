library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  Logger, WasmMemMgr, VGA;

procedure Init;
begin
  initHeapMgr;
end;

procedure AfterInit;
begin
  writeLog('Hello from hello_minimal!')
end;

procedure Update;
begin
end;

procedure Draw;
begin
  Cls($FF101010);
  VgaUpload;
  VgaPresent
end;

exports
  Init, AfterInit, Update, Draw;

begin
{ Starting point is intentionally left empty }
end.
