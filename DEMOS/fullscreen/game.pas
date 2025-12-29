library Game;

{$Mode ObjFPC}
{$J-}

uses
  Conv, FPS,
  ImgRef, ImgRefFast,
  Keyboard, Mouse,
  ImmedGui, Loading, Logger, Panic, Timing,
  WasmMemMgr, VGA, Fullscreen,
  Assets;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc, lastSpacebar: boolean;

  { Init your game state here }
  actualGameState: TGameStates;
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

procedure beginLoadingState;
begin
  actualGameState := GameStateLoading;
  loadAssets
end;

procedure beginPlayingState;
begin
  { Initialise game state here }
  hideCursor;
  actualGameState := GameStatePlaying;
  gameTime := 0.0;

  initImmediateGUI;
  guiSetFont(defaultFont, defaultFontGlyphs);
end;


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
begin
  beginPlayingState;
  fitCanvas;
  writeLog('afterInit end')
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateGUILastMouseButton;
  updateMouse;
  updateGUIMousePoint;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then endFullscreen;
  end;

  if lastSpacebar <> isKeyDown(SC_SPACE) then begin
    lastSpacebar := isKeyDown(SC_SPACE);
    if lastSpacebar then toggleFullscreen;
  end;

  gameTime := gameTime + dt;
  resetWidgetIndices
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;

  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := 'Press Spacebar to toggle fullscreen';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  if ImageButton(
    vgaWidth - 30, vgaHeight - 30,
    imgFullscreen, imgFullscreen, imgFullscreen) then
    toggleFullscreen;

  printDefault('Fullscreen? ' + boolStr(getFullscreenState), 10, 30);

  resetActiveWidget;
  drawMouse;
  vgaFlush
end;

exports
  { Main game procedures }
  beginLoadingState,
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

