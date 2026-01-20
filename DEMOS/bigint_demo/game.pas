library Game;

{$Mode ObjFPC}

uses
  Conv, FPS, Fullscreen,
  ImgRef, ImgRefFast,
  Loading, Keyboard, Logger, Mouse,
  Timing, WasmMemMgr, VGA,
  Assets, BigInt;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );

const
  SC_ESC = $01;
  SC_SPACE = $39;

  SC_LEFT = $4B;
  SC_RIGHT = $4D;

var
  lastEsc: boolean;
  lastLeft, lastRight: boolean;

  { Used by BigInt }
  stringBuffer: array[0..255] of byte;

  { Game state variables }
  actualGameState: TGameStates;
  gameTime: double;
  points: string; { BigInt }

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

  points := '123';

  { Addition }
  BigIntA := '12';
  BigIntB := '34';
  addBigInt;

  writeLog('a = ' + BigIntA);
  writeLog('b = ' + BigIntB);
  writeLog('a + b = ' + BigIntResult);

  { Subtraction }
  BigIntA := '56';
  BigIntB := '78';
  subtractBigInt;

  writeLog('a = ' + BigIntA);
  writeLog('b = ' + BigIntB);
  writeLog('a - b = ' + BigIntResult);

  { Multiplication }
  BigIntA := '6';
  BigIntB := '7';
  multiplyBigInt;

  writeLog('a = ' + BigIntA);
  writeLog('b = ' + BigIntB);
  writeLog('a * b = ' + BigIntResult);

  { Comparison }
  BigIntA := '6';
  BigIntB := '7';
  compareBigInt;

  writeLog('a = ' + BigIntA);
  writeLog('b = ' + BigIntB);
  writeLog('compare(a, b) = ' + BigIntResult);
end;

{ Used by BigInt }
function getStringBuffer: pointer;
begin
  getStringBuffer := @stringBuffer
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


procedure printCentred(const text: string; const y: integer);
var
  w: integer;
begin
  w := measureDefault(text);
  printDefault(text, (vgaWidth - w) div 2, y)
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  if lastLeft <> isKeyDown(SC_LEFT) then begin
    lastLeft := isKeyDown(SC_LEFT);

    if lastLeft then begin
      BigIntA := points;
      BigIntB := '1000';
      compareBigInt;

      { if points > 1000 }
      if parseInt(BigIntResult) > 0 then begin
        BigIntB := '10';
        divideBigInt;
        points := BigIntResult
      end;
    end;
  end;

  if lastRight <> isKeyDown(SC_RIGHT) then begin
    lastRight := isKeyDown(SC_RIGHT);

    if lastRight then begin
      BigIntA := points;
      BigIntB := '10';
      multiplyBigInt;

      points := BigIntResult
    end;
  end;

  gameTime := gameTime + dt
end;

procedure draw;
var
  formattedPoints: string;
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

  printCentred(points, 140);

  BigIntA := points;
  formatBigInt;
  formattedPoints := BigIntResult;
  printCentred(formattedPoints, 150);

  BigIntA := points;
  formatBigIntScientific;
  formattedPoints := BigIntResult;
  printCentred(formattedPoints, 160);

  printCentred('Left - Decrease | Right - Increase', 180);

  drawMouse;
  drawFPS;

  vgaFlush
end;

exports
  getStringBuffer,
  beginLoadingState,
  { Main game procedures }
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.

