library Game;

{$Mode ObjFPC}
{$H+}  { Use AnsiStrings }
{$J-}  { Switch off assignments to typed constants }

uses
  SysUtils,
  EngineCore, EngineFonts, Logger, WasmHost,
  IntroScr, Loading, Fullscreen,
  Conv, FPS,
  Keyboard, Mouse,
  ImgRef, ImgRefFast, SprEffects,
  Timing, VGA,
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


procedure DrawFPS;
begin
  PrintDefault('FPS:' + i32str(GetLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  Spr(imgCursor, mouseX, mouseY)
end;

procedure BeginIntroState;
begin
  actualGameState := GameStateIntro;
  FitCanvas;

  introSlide := 1;
  introSlideEndTick := getTimer + 2.0;
end;

procedure BeginLoadingState;
begin
  actualGameState := GameStateLoading;
  FitCanvas;
  RequestAssetLoad
end;

procedure BeginPlayingState;
begin
  HideCursor;
  FitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;
  
  ReplaceColour(DefaultFontPtr^.imgHandle, $FFFFFFFF, $FF000000);
end;


procedure OnReady;
begin
  BeginPlayingState;
end;

procedure Update;
var
  shouldSkip: boolean;
begin
  UpdateDeltaTime;
  IncrementFPS;

  if actualGameState = GameStateIntro then begin
    shouldSkip := false;

    { Handle inputs }
    if lastSpacebar <> IsKeyDown(SC_SPACE) then begin
      lastSpacebar := IsKeyDown(SC_SPACE);
      if lastSpacebar then shouldSkip := true
    end;

    if lastEnter <> IsKeyDown(SC_ENTER) then begin
      lastEnter := IsKeyDown(SC_ENTER);
      if lastEnter then shouldSkip := true
    end;

    { Handle next slide }
    if GetTimer >= introSlideEndTick then
      shouldSkip := true;

    if shouldSkip then begin
      introSlideEndTick := GetTimer + 2.0;
      inc(introSlide);
    end;

    if introSlide > IntroSlides then begin
      UnloadIntro;
      BeginLoadingState
    end;

    exit
  end;

  { Handle inputs }
  UpdateMouse;

  if lastEsc <> IsKeyDown(SC_ESCAPE) then begin
    lastEsc := IsKeyDown(SC_ESCAPE);

    if lastEsc then begin
      WriteLog('ESC is pressed!');
      SignalDone
    end;
  end;

  { Handle game state updates }
  gameTime := gameTime + DeltaTime
end;

procedure Draw;
begin
  if actualGameState in [GameStateIntro, GameStateLoading] then
  case actualGameState of
    GameStateIntro: begin
      RenderIntro(introSlide);

      { Debug intro state }
      PrintDefault('(Intro slide ' + i32str(introSlide) + ')', 30, 30);
      PrintDefault('Slide end tick: ' + f32str(introSlideEndTick), 30, 40);

      exit
    end;
    GameStateLoading: begin
      RenderLoadingScreen;
      exit
    end else
  end;

  Cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    Spr(imgDosuEXE[1], 148, 88)
  else
    Spr(imgDosuEXE[0], 148, 88);

  PrintDefaultCentred('Hello world!', vgaWidth div 2, 120);

  DrawMouse;
  DrawFPS;

  VgaUpload;
  VgaPresent
end;

exports
  BeginIntroState,
  BeginLoadingState,
  OnReady, Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

