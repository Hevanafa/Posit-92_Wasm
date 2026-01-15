library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  Fullscreen, ImgRefFast, Timing,
  WasmMemMgr, VGA,
  Assets;

var
  { Game state variables }
  gameTime: double;

procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime
end;

procedure afterInit;
begin
  fitCanvas;

  { Initialise game state here }
  gameTime := 0.0;
end;

procedure update;
begin
  updateDeltaTime;

  { Handle game state updates }
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


