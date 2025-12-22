library Game;

{$Mode ObjFPC}

uses
  Conv, Keyboard, Mouse,
  ImgRef, ImgRefFast, Logger,
  Timing, VGA, WasmHeap, WasmMemMgr,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;

  ptr1, ptr2: pointer;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;

  { Test memory allocation & free memory }
  ptr1 := getmem(100);
  ptr2 := getmem(50);

  writeLog('Free heap: ' + i32str(GetFreeHeapSize));

  freemem(ptr1);

  writeLog('After free: ' + i32str(GetFreeHeapSize));
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;
end;

procedure update;
begin
  updateDeltaTime;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then signalDone;
  end;

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  printDefault('Free heap: ' + i32str(GetFreeHeapSize) + 'B', 10, 10);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
  vgaFlush
end;

exports
  { Main game procedures }
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

