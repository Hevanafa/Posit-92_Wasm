library Game;

{$Mode ObjFPC}
{$H+}  { Use AnsiStrings }
{$J-}  { Switch off assignments to typed constants }

uses
  SysUtils,
  IntroScr, Loading, Fullscreen,
  Conv, FPS, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast, SprEffects,
  PostProc, Timing, WasmMemMgr,
  VGA,
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
  lastEsc: boolean;
  lastSpacebar, lastEnter: boolean;

  { Intro state variables }
  introSlide: integer;
  introSlideEndTick: double;

  { Init your game state here }
  actualGameState: TGameStates;
  gameTime: double;


{ Use this to set `done` to true }
procedure SignalDone; external 'env' name 'SignalDone';
procedure HideCursor; external 'env' name 'HideCursor';
procedure HideLoadingOverlay; external 'env' name 'HideLoadingOverlay';
procedure LoadAssets; external 'env' name 'LoadAssets';

procedure DrawFPS;
begin
  PrintDefault('FPS:' + i32str(GetLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure BeginIntroState;
begin
  HideLoadingOverlay;
  fitCanvas;

  actualGameState := GameStateIntro;
  introSlide := 1;
  introSlideEndTick := getTimer + 2.0;
end;

procedure BeginLoadingState;
begin
  actualGameState := GameStateLoading;
  fitCanvas;
  LoadAssets
end;

procedure BeginPlayingState;
begin
  HideCursor;
  fitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;
  
  replaceColour(defaultFont.imgHandle, $FFFFFFFF, $FF000000);
end;


procedure Init;
begin
  InitHeapMgr;
  InitDeltaTime;
  InitFPSCounter
end;

procedure AfterInit;
begin
  BeginPlayingState;
end;

procedure Update;
var
  shouldSkip: boolean;
begin
  updateDeltaTime;
  IncrementFPS;

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
      BeginLoadingState
    end;

    exit
  end;

  { Handle inputs }
  updateMouse;

  if lastEsc <> isKeyDown(SC_ESCAPE) then begin
    lastEsc := isKeyDown(SC_ESCAPE);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      SignalDone
    end;
  end;

  { Handle game state updates }
  gameTime := gameTime + dt
end;

procedure Draw;
begin
  if actualGameState in [GameStateIntro, GameStateLoading] then
  case actualGameState of
    GameStateIntro: begin
      renderIntro(introSlide);

      { Debug intro state }
      PrintDefault('(Intro slide ' + i32str(introSlide) + ')', 30, 30);
      PrintDefault('Slide end tick: ' + f32str(introSlideEndTick), 30, 40);

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

  PrintDefaultCentred('Hello world!', vgaWidth div 2, 120);

  DrawMouse;
  DrawFPS;

  VgaUpload;
  VgaPresent
end;

exports
  BeginIntroState,
  BeginLoadingState,
  Init, AfterInit, Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

