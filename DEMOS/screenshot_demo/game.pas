library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  Loading, Fullscreen,
  Conv, FPS, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Timing, WasmMemMgr, VGA,
  Assets;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );

const
  CornflowerBlue = $FF6495ED;

var
  lastF2: boolean;

  { Game state variables }
  actualGameState: TGameStates;
  gameTime: double;


{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure hideCursor; external 'env' name 'hideCursor';
procedure hideLoadingOverlay; external 'env' name 'hideLoadingOverlay';
procedure loadAssets; external 'env' name 'loadAssets';

procedure takeScreenshot; external 'env' name 'takeScreenshot';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure beginLoadingState;
begin
  actualGameState := GameStateLoading;
  fitCanvas;
  loadAssets
end;

procedure beginPlayingState;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;
end;


procedure init;
begin
  initHeapMgr;
  initDeltaTime;
  initFPSCounter
end;

procedure afterInit;
begin
  beginPlayingState
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  { Handle inputs }
  updateMouse;

  if isKeyDown(SC_ESCAPE) then signalDone;

  if lastF2 <> isKeyDown(SC_F2) then begin
    lastF2 := isKeyDown(SC_F2);

    if lastF2 then takeScreenshot;
  end;

  { Handle game state updates }
  gameTime := gameTime + dt
end;

procedure draw;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen; exit
  end;

  cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  printDefaultCentred('Press F2 to take a screenshot', vgaWidth div 2, 120);

  drawMouse;
  drawFPS;

  vgaFlush
end;

exports
  beginLoadingState,
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.
