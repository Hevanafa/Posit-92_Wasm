library Game;

{$Mode ObjFPC}

uses
  BMFont, Conv, FPS,
  Logger, Keyboard, Mouse,
  ImgRef, ImgRefFast,
  PostProc, Timing, VGA, WasmMemMgr, WasmHeap,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  Black = $FF000000;

var
  lastEsc, lastSpacebar: boolean;

  { Init your game state here }
  gameTime: double;
  applyBlur: boolean;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
var
  tempImg: longint;
begin
  { Initialise game state here }
  hideCursor;

  applyBlur := true;

  writeLog('Free heap');
  tempImg := newImage(10, 10);
  writeLogI32(GetFreeHeapSize);

  freeImage(tempImg);
  writeLogI32(GetFreeHeapSize);
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then signalDone;
  end;

  if lastSpacebar <> isKeyDown(SC_SPACE) then begin
    lastSpacebar := isKeyDown(SC_SPACE);
    if lastSpacebar then
      applyBlur := not applyBlur;
  end;

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  spr(imgDreamscapeCrossing, 0, 0);

  if applyBlur then
    applyFullBoxBlur(1);

  printBlack('Press Spacebar to toggle blur', 10, vgaHeight - 20);

  s := 'Art by [Unknown Artist]';
  w := measureDefault(s);
  printBlack(s, (vgaWidth - w) - 10, vgaHeight - 20);

  drawFPS;
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

