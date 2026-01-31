library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  Logger, WasmMemMgr, VGA;

type
  TGameString = record
    data: PWideChar;
    len: word;  { string length }
    capacity: word;  { buffer size }
  end;

var
  gs: TGameString;

procedure init;
var
  ws: WideString;
begin
  ws := 'Hello!';
  initHeapMgr;

  gs.data := PWideChar(ws);
  gs.len := length(ws);
end;

procedure afterInit;
var
  a: word;
begin
  writeLog('gs.len');
  writeLogI32(gs.len);

  for a:=0 to gs.len - 1 do
    writeLogI32(ord(gs.data[a]));
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
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.
