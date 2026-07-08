{
  Boilerplate project with the intro sequence
  Part of Posit-92 game engine
  Mixins: bmfont, sound
}

library Game;

{$Mode ObjFPC}
{$H+}  { Use AnsiStrings }
{$J-}  { Switch off assignments to typed constants }

uses
  P92Core, P92Fonts, P92AssetRegistry,
  P92Logger, P92WasmHost, P92Loading,
  P92Conversions, P92FPS,
  P92Keyboard, P92Mouse,
  P92Tex, P92TexDraw, P92TexEffects,
  P92Timing, P92VGA,
  Assets, IntroScr;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStatePlaying = 2
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


procedure DrawMouse;
begin
  Spr(imgCursor, mouseX, mouseY)
end;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');

  imgDosuExe[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuExe[1] := RequestImage('assets/images/dosu_2.png');

  imgPosit92Logo := RequestImage('assets/images/posit-92_32px.png');
  imgFPCLogo := RequestImage('assets/images/fpc_logo.png');
  imgWasmLogo := RequestImage('assets/images/wasm_logo.png');
end;

procedure BeginIntroState;
begin
  actualGameState := GameStateIntro;
  FitCanvas;

  introSlide := 1;
  introSlideEndTick := getTimer + 2.0;
end;

procedure BeginPlayingState;
begin
  HideCursor;
  FitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;
  
  ReplaceColour(DefaultFontPtr^.texHandle, $FFFFFFFF, $FF000000);
end;


procedure OnReady;
begin
  BeginIntroState
end;

procedure Update;
var
  shouldSkip: boolean;
begin
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
      BeginPlayingState
    end;

    exit
  end;

  { Handle inputs }
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
  if actualGameState = GameStateIntro then
  case actualGameState of
    GameStateIntro: begin
      RenderIntro(introSlide);

      { Debug intro state }
      PrintDefault('(Intro slide ' + i32str(introSlide) + ')', 30, 30);
      PrintDefault('Slide end tick: ' + f32str(introSlideEndTick), 30, 40);

      exit
    end;
  else
  end;

  Cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    Spr(imgDosuEXE[1], 148, 88)
  else
    Spr(imgDosuEXE[0], 148, 88);

  PrintDefaultCentred('Hello world!', vgaWidth div 2, 120);

  DrawMouse;
  DrawFPS;
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

