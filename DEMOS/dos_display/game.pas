library Game;

{$Mode TP}

uses
  Conv, FPS, Loading, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Timing, WasmMemMgr, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  CharBufferSize = 80 * 25;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  charBuffer: array[0..CharBufferSize - 1] of char;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure cls;
begin
  fillchar(charBuffer, CharBufferSize, 0)
end;

procedure printChar(const c: char; const x, y: integer);
var
  charcode: byte;
  row, col: word;
begin
  charcode := ord(c);
  row := charcode div 16;
  col := charcode mod 16;
  sprRegion(imgCGAFont, col * 8, row * 8, 8, 8, x, y)
end;

procedure print(const text: string; const x, y: integer);
var
  a: word;
  left: integer;
begin
  left := x;

  for a:=1 to length(text) do begin
    printChar(text[a], left, y);
    inc(left, 8)
  end;
end;

procedure drawFPS;
begin
  print('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit; public name 'afterInit';
begin
  { Initialise game state here }
  hideCursor;
  { replaceColours(defaultFont.imgHandle, $FFFFFFFF, $FF000000); }
end;

procedure update; public name 'update';
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

procedure draw; public name 'draw';
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  { Your drawing code here }

  drawMouse;
  drawFPS;

  vgaFlush
end;

{ Requires at least 1 exported member }
exports init;

begin
{ Starting point is intentionally left empty }
end.

