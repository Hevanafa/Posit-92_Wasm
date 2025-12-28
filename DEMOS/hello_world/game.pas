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

  { Intro variables }
  introEndTick: double;

  { Init your game state here }
  actualGameState: TGameStates;
  gameTime: double;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure loadAssets; external 'env' name 'loadAssets';

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
  loadAssets
end;

procedure renderIntro;
begin
  cls($FF000000);

  printDefault('(Intro screen)', 30, 30);

  vgaFlush
end;


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
  initFPSCounter;

  actualGameState := GameStateIntro;
  introEndTick := getTimer + 3.0
end;

procedure afterInit;
begin
  hideCursor;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;
  
  replaceColours(defaultFont.imgHandle, $FFFFFFFF, $FF000000);
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  if actualGameState = GameStateIntro then begin
    { TODO: Handle inputs }

    if getTimer >= introEndTick then 
      beginLoadingState;
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
  if actualGameState = GameStateIntro then begin
    renderIntro;
    exit
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
  { Main game procedures }
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

