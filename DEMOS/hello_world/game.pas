library Game;

{$Mode ObjFPC}

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

  CornflowerBlue = $FF6495ED;

var
  lastEsc: boolean;

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

  writeLog('beginIntroState');

  actualGameState := GameStateIntro;
  introSlide := 1;
  introSlideEndTick := getTimer + 2.0;

  writeLogF32(introSlideEndTick);
end;

procedure beginLoadingState;
begin
  writeLog('beginLoadingState');

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

procedure renderIntro;
begin
  cls($FF000000);

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
begin
  updateDeltaTime;
  incrementFPS;

  if actualGameState = GameStateIntro then begin
    { TODO: Handle inputs }

    if getTimer >= introSlideEndTick then begin
      writeLog('Next intro slide');
      introSlideEndTick := getTimer + 2.0;
      inc(introSlide);
    end;

    if introSlide > 2 then beginLoadingState;

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
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

