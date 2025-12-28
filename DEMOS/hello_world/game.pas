library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  IntroScr, Loading,
  Conv, FPS, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  PostProc, Timing, WasmMemMgr, VGA,
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

  IntroSlides = 2;

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

  writeLogF32(introSlideEndTick);
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
  
  replaceColours(defaultFont.imgHandle, $FFFFFFFF, $FF000000);
end;


procedure printDefaultCentred(const text: string; const cx, y: smallint);
var
  w: word;
begin
  w := measureDefault(text);
  printDefault(text, cx - w div 2, y)
end;

procedure renderIntro;
begin
  cls($FF000000);

  case introSlide of
    1: begin
      spr(imgPosit92Logo, 144, 84);
      printDefaultCentred('Made with Posit-92', vgaWidth div 2, 126)
    end;

    2: begin
      printDefaultCentred('Made with', vgaWidth div 2, 44);

      spr(imgFPCLogo, 75, 67);
      spr(imgWasmLogo, 180, 67);

      printDefaultCentred('Free Pascal', 108, 144);
      printDefaultCentred('Compiler', 108, 154);
      printDefaultCentred('WebAssembly', 212, 144);
    end;
  end;

  { Debug intro state }
  printDefault('(Intro slide ' + i32str(introSlide) + ')', 30, 30);
  printDefault('Slide end tick: ' + f32str(introSlideEndTick), 30, 40);

  vgaFlush
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

    if introSlide > IntroSlides then beginLoadingState;

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
      renderIntro; exit
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

