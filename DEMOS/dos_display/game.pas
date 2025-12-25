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

  BufferWidth = 80;
  BufferHeight = 25;
  CharBufferSize = BufferWidth * BufferHeight;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;

  cursorLeft, cursorTop: integer;
  charBuffer: array[0..CharBufferSize - 1] of char;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure cls;
begin
  fillchar(charBuffer, CharBufferSize, 0);
  cursorLeft := 0;
  cursorTop := 0
end;

procedure blitChar(const c: char; const x, y: integer);
var
  charcode: byte;
  row, col: word;
begin
  charcode := ord(c);
  row := charcode div 16;
  col := charcode mod 16;
  sprRegion(imgCGAFont, col * 8, row * 8, 8, 8, x, y)
end;

procedure blitText(const text: string; const x, y: integer);
var
  a: word;
  left: integer;
begin
  if not isImageSet(imgCGAFont) then begin
    writeLog('blitText: image is unset');
    exit
  end;

  left := x;

  for a:=1 to length(text) do begin
    blitChar(text[a], left, y);
    inc(left, 8)
  end;
end;

procedure incCursorTop;
begin
  cursorLeft := 0;
  inc(cursorTop)
end;

procedure incCursorLeft;
begin
  inc(cursorLeft);
  if cursorLeft >= BufferWidth then
    incCursorTop;
end;

procedure print(const text: string);
var
  a: word;
begin
  for a:=1 to length(text) do begin
    charBuffer[cursorTop * BufferWidth + cursorLeft] := text[a];
    incCursorLeft
  end;
end;

procedure printLn(const text: string);
begin
  print(text);
  incCursorTop
end;


procedure drawFPS;
begin
  blitText('FPS:' + i32str(getLastFPS), 240, 0);
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

procedure initDefaultFont; public name 'initDefaultFont';
var
  a, b: word;
  image: PImageRef;
begin
  if not isImageSet(imgCGAFont) then begin
    writeLog('initDefaultFont: image is unset');
    exit
  end;

  image := getImagePtr(imgCGAFont);

  for b:=0 to getImageHeight(imgCGAFont) - 1 do
  for a:=0 to getImageWidth(imgCGAFont) - 1 do
    if unsafeSprGetAlpha(image, a, b) = 255 then
      unsafeSprPset(image, a, b, $FFAAAAAA); { light grey }
end;

procedure afterInit; public name 'afterInit';
begin
  { Initialise game state here }
  hideCursor;

  cls;
  printLn('Welcome to Posit-92 Wasm!')
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
  a, b: integer;
  
begin
  vgaCls($FF000000);

  { Your drawing code here }
  for b:=0 to BufferHeight - 1 do
  for a:=0 to BufferWidth - 1 do
    blitChar(charBuffer[a + b * BufferWidth], a * 8, b * 8);

  drawMouse;
  drawFPS;

  vgaFlush
end;

{ Requires at least 1 exported member }
exports init;

begin
{ Starting point is intentionally left empty }
end.

