library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, Keyboard, Logger, Mouse,
  Panic, Sounds, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;

  stringBuffer: array[0..255] of byte;
  { BigInt "registers". The result register isn't always a number }
  BigIntA, BigIntB, BigIntResult: string;

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

procedure addBigInt; external 'env' name 'addBigInt';

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

  BigIntA := '12';
  BigIntB := '34';
  addBigInt;

  writeLog('a = ' + BigIntA);
  writeLog('b = ' + BigIntB);
  writeLog('Result: ' + BigIntResult)
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

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

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

