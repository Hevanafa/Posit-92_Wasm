library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  WasmMemMgr, VGA;

procedure init;
begin
  initMemMgr;
  initBuffer;
end;

procedure afterInit;
begin
end;

procedure update;
begin
end;

procedure draw;
begin
  cls($FF101010);

  vgaFlush
end;

exports
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.


