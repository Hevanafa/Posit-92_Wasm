library Game;

{$Mode ObjFPC}
{$H+}
{$J-}  { Switch off assignments to typed constants }

uses
  Loading, Fullscreen,
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Timing, WasmMemMgr, VGA,
  Assets;

const
  CornflowerBlue = $FF6495ED;

var
  { Game state variables }
  gameTime: double;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure hideCursor; external 'env' name 'hideCursor';
procedure hideLoadingOverlay; external 'env' name 'hideLoadingOverlay';
procedure loadAssets; external 'env' name 'loadAssets';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;


procedure init;
begin
  initHeapMgr;
  initDeltaTime
end;

procedure afterInit;
begin
  loadAssets;
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  gameTime := 0.0;
end;

procedure update;
begin
  updateDeltaTime;

  { Handle inputs }
  updateMouse;

  if isKeyDown(SC_ESCAPE) then signalDone;

  { Handle game state updates }
  gameTime := gameTime + dt
end;

procedure draw;
begin
  cls(CornflowerBlue);

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
