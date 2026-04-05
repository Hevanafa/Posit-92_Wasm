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
  t, x, y: smallint;

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

  t := 0;
  x := 96;
  y := 24;
end;

procedure update;
begin
  updateDeltaTime;

  { Handle inputs }
  updateMouse;

  if isKeyDown(SC_ESCAPE) then signalDone;

  if isKeyDown(SC_UP) then dec(y);
  if isKeyDown(SC_DOWN) then inc(y);
  if isKeyDown(SC_LEFT) then dec(x);
  if isKeyDown(SC_RIGHT) then inc(x);

  { Handle update logic }
  gameTime := gameTime + dt;
  inc(t)
end;

procedure draw;
begin
  cls($FF94B0C2);

  sprRegionStretch(imgTicsy, t mod 60 div 30 * 16, 0, 16, 16, x, y, 48, 48);

  printDefault('HELLO WORLD!', 84, 84);

  drawMouse;

  vgaFlush
end;

exports
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.
