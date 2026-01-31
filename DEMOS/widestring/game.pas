library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }
{$Notes OFF}

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

procedure StrCopy(var dest: TGameString; const src: WideString);
begin
  dest.len := length(src);
  dest.data := getmem(dest.len * sizeof(widechar));
  move(PWideChar(src)^, dest.data^, dest.len * sizeof(widechar))
end;

procedure FreeStr(var gs: TGameString);
begin
  if gs.data <> nil then begin
    freemem(gs.data);
    gs.data := nil;
    gs.len := 0
  end;
end;

{ dest is automatically freed, src remains }
procedure StrCat(var dest: TGameString; const src: TGameString);
var
  newLen: word;
  newData: PWideChar;
begin
  newLen := dest.len + src.len;
  newData := getmem(newLen + sizeof(widechar));

  if dest.len > 0 then
    move(dest.data^, newData^, dest.len * sizeof(widechar));

  if src.len > 0 then
    move(src.data^, (newData + dest.len)^, src.len * sizeof(widechar));

  FreeStr(dest);
  dest.data := newData;
  dest.len := newLen
end;

procedure init;
var
  ws: WideString;
  s2: TGameString;
begin
  ws := 'Hello';
  initHeapMgr;

  StrCopy(gs, ws);
  StrCopy(s2, ' world!');
  StrCat(gs, s2);
  
  FreeStr(s2)
end;

procedure afterInit;
var
  a: word;
begin
  writeLog('gs.len');
  writeLogI32(gs.len);

  for a:=0 to gs.len - 1 do
    writeLogI32(ord(gs.data[a]));

  FreeStr(gs);

  if gs.data = nil then
    writeLog('gs.data is nil!')
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
