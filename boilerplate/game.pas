library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  IntroScr, Loading, Conv,
  FPS, Logger, Keyboard, Mouse,
  ImgRefFast, Timing, WasmMemMgr,
  VGA,
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
  SC_ENTER = $1C;

  CornflowerBlue = $FF6495ED;

var
  lastEsc: boolean;
  lastSpacebar, lastEnter: boolean;

  { Intro state variables }
  introSlide: integer;
  introSlideEndTick: double;

  { Init your game state here }
  actualGameState: TGameStates;
  gameTime: double;


{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure hideCursor; external 'env' name 'hideCursor';
procedure hideLoadingOverlay; external 'env' name 'hideLoadingOverlay';
procedure loadAssets; external 'env' name 'loadAssets';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure beginIntroState;
begin
  hideLoadingOverlay;

  actualGameState := GameStateIntro;
  introSlide := 1;
  introSlideEndTick := getTimer + 2.0;
end;

procedure beginLoadingState;
begin
  actualGameState := GameStateLoading;
  loadAssets
end;

procedure beginPlayingState;
begin
  actualGameState := GameStatePlaying;
  
  { Initialise game state here }
  hideCursor;
  actualGameState := GameStatePlaying;
  gameTime := 0.0;
end;


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
  initFPSCounter
end;

procedure afterInit;
begin
  beginPlayingState;
end;

procedure update;
var
  shouldSkip: boolean;
begin
  updateDeltaTime;
  incrementFPS;

  if actualGameState = GameStateIntro then begin
    shouldSkip := false;

    { Handle inputs }
    if lastSpacebar <> isKeyDown(SC_SPACE) then begin
      lastSpacebar := isKeyDown(SC_SPACE);
      if lastSpacebar then shouldSkip := true
    end;

    if lastEnter <> isKeyDown(SC_ENTER) then begin
      lastEnter := isKeyDown(SC_ENTER);
      if lastEnter then shouldSkip := true
    end;

    { Handle next slide }
    if getTimer >= introSlideEndTick then
      shouldSkip := true;

    if shouldSkip then begin
      introSlideEndTick := getTimer + 2.0;
      inc(introSlide);
    end;

    if introSlide > IntroSlides then begin
      unloadIntro;
      beginLoadingState
    end;

    exit
  end;

  { Handle inputs }
  updateMouse;

  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  { Handle game state updates }
  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  if actualGameState in [GameStateIntro, GameStateLoading] then
  case actualGameState of
    GameStateIntro: begin
      renderIntro(introSlide);

      { Debug intro state }
      printDefault('(Intro slide ' + i32str(introSlide) + ')', 30, 30);
      printDefault('Slide end tick: ' + f32str(introSlideEndTick), 30, 40);

      exit
    end;
    GameStateLoading: begin
      renderLoadingScreen; exit
    end else
  end;

  cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
  drawFPS;

  vgaFlush
end;

exports
  beginIntroState,
  beginLoadingState,
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

