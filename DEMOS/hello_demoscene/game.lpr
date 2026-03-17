library Game;

{$Mode ObjFPC}
{$H+}  { Use AnsiStrings }
{$J-}  { Switch off assignments to typed constants }

uses
  Loading, Fullscreen, Keyboard, Mouse,
  ImgRefFast, Timing, WasmMemMgr, VGA,
  Assets;

var
  { Game state variables }
  gameTime: double;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure hideCursor; external 'env' name 'hideCursor';
procedure loadAssets; external 'env' name 'loadAssets';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure init;
begin
  initHeapMgr;
  initDeltaTime;

  loadAssets;
end;

procedure afterInit;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  gameTime := 0.0;
end;

procedure update;
begin
  updateDeltaTime;

  updateMouse;
  if isKeyDown(SC_ESCAPE) then signalDone;

  gameTime := gameTime + dt
end;

procedure draw;
begin
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  printDefaultCentred('Hello world!', vgaWidth div 2, 120);

  drawMouse;

  vgaFlush
end;

exports
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.
