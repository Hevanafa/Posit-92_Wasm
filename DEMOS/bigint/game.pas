library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, Keyboard, Logger, Mouse,
  Panic, Sounds, Timing, VGA,
  Assets;

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
  { BigInt "registers". The result register isn't always a number }
  BigIntA, BigIntB, BigIntResult: string;

  { Init your game state here }
  gameTime: double;
  points: string; { BigInt }

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;


function getStringBuffer: pointer; public name 'getStringBuffer';
begin
  getStringBuffer := @stringBuffer
end;

procedure loadBigIntResult(const textPtr: pointer; const textLen: integer); public name 'loadBigIntResult';
begin
  BigIntResult := strPtrToString(textPtr, textLen)
end;

function getBigIntAPtr: pointer; public name 'getBigIntAPtr';
begin
  getBigIntAPtr := @BigIntA
end;

function getBigIntBPtr: pointer; public name 'getBigIntBPtr';
begin
  getBigIntBPtr := @BigIntB
end;

function getBigIntResultPtr: pointer; public name 'getBigIntResultPtr';
begin
  getBigIntResultPtr := @BigIntResult
end;

procedure addBigInt; external 'env' name 'addBigInt';
procedure subtractBigInt; external 'env' name 'subtractBigInt';
procedure multiplyBigInt; external 'env' name 'multiplyBigInt';

{ Sets the Result register to either -1, 0, or 1 }
procedure compareBigInt; external 'env' name 'compareBigInt';

{ Requires only register A, outputs to the Result register }
procedure formatBigInt; external 'env' name 'formatBigInt';


procedure init;
begin
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;

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

      { if points < 1000 }
      { TODO: Handle BigInt division }
      { if parseInt(BigIntResult) >= 0 then }
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

  printCentred('Left - Decrease | Right - Increase', 180);

  drawMouse;
  drawFPS;

  flush
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

