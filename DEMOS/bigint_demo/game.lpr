library Game;

{$Mode ObjFPC}

uses
  EngineCore, EngineFonts, WasmHost, WasmMemMgr,
  Conv, FPS, Fullscreen,
  ImgRef, ImgRefFast,
  Loading, Keyboard, Logger, Mouse,
  Timing, VGA,
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

procedure DrawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure BeginLoadingState;
begin
  actualGameState := GameStateLoading;
  fitCanvas;

  RequestAssetLoad
end;

procedure BeginPlayingState;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;

  points := '123';

  { Addition }
  bigIntA := '12';
  bigIntB := '34';
  AddBigInt;

  writeLog('a = ' + bigIntA);
  writeLog('b = ' + bigIntB);
  writeLog('a + b = ' + bigIntResult);

  { Subtraction }
  bigIntA := '56';
  bigIntB := '78';
  SubtractBigInt;

  writeLog('a = ' + bigIntA);
  writeLog('b = ' + bigIntB);
  writeLog('a - b = ' + bigIntResult);

  { Multiplication }
  bigIntA := '6';
  bigIntB := '7';
  MultiplyBigInt;

  writeLog('a = ' + bigIntA);
  writeLog('b = ' + bigIntB);
  writeLog('a * b = ' + bigIntResult);

  { Comparison }
  bigIntA := '6';
  bigIntB := '7';
  CompareBigInt;

  writeLog('a = ' + bigIntA);
  writeLog('b = ' + bigIntB);
  writeLog('compare(a, b) = ' + bigIntResult);
end;

{ Used by BigInt }
function GetStringBuffer: pointer;
begin
  GetStringBuffer := @stringBuffer
end;


procedure OnReady;
begin
  BeginPlayingState
end;


procedure PrintCentred(const text: string; const y: integer);
var
  w: integer;
begin
  w := MeasureDefault(text);
  PrintDefault(text, (vgaWidth - w) div 2, y)
end;

procedure Update;
begin
  updateDeltaTime;
  incrementFPS;

  updateMouse;

  { Your Update logic here }
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
      bigIntA := points;
      bigIntB := '1000';
      CompareBigInt;

      { if points > 1000 }
      if parseInt(bigIntResult) > 0 then begin
        bigIntB := '10';
        DivideBigInt;
        points := bigIntResult
      end;
    end;
  end;

  if lastRight <> isKeyDown(SC_RIGHT) then begin
    lastRight := isKeyDown(SC_RIGHT);

    if lastRight then begin
      bigIntA := points;
      bigIntB := '10';
      MultiplyBigInt;

      points := bigIntResult
    end;
  end;

  gameTime := gameTime + DeltaTime
end;

procedure Draw;
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

  PrintCentred(points, 140);

  bigIntA := points;
  FormatBigInt;
  formattedPoints := bigIntResult;
  PrintCentred(formattedPoints, 150);

  bigIntA := points;
  FormatBigIntScientific;
  formattedPoints := bigIntResult;
  PrintCentred(formattedPoints, 160);

  PrintCentred('Left - Decrease | Right - Increase', 180);

  DrawMouse;
  DrawFPS;

  VgaUpload;
  VgaPresent
end;

exports
  GetStringBuffer,
  BeginLoadingState,
  { Main game procedures }
  OnReady, Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

