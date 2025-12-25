library Game;

{$Mode TP}

uses
  Conv, FPS, Graphics, Loading, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Timing, WasmMemMgr, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_BACKSPACE = $0E;
  SC_ENTER = $1C;

  SC_Q = $10;
  SC_W = $11;
  SC_E = $12;
  SC_R = $13;
  SC_T = $14;
  SC_Y = $15;
  SC_U = $16;
  SC_I = $17;
  SC_O = $18;
  SC_P = $19;

  SC_A = $1E;
  SC_S = $1F;
  SC_D = $20;
  SC_F = $21;
  SC_G = $22;
  SC_H = $23;
  SC_J = $24;
  SC_K = $25;
  SC_L = $26;

  SC_Z = $2C;
  SC_X = $2D;
  SC_C = $2E;
  SC_V = $2F;
  SC_B = $30;
  SC_N = $31;
  SC_M = $32;

  SC_SPACE = $39;

  BufferWidth = 80;
  BufferHeight = 25;
  CharBufferSize = BufferWidth * BufferHeight;

  Black = $FF000000;
  LightGrey = $FFAAAAAA;
  White = $FFFFFFFF;

{type
  AllowedScancodes = (
    SC_Q, SC_W, SC_E, SC_R, SC_T, SC_Y, SC_U, SC_I, SC_O, SC_P,
    SC_A, SC_S, SC_D, SC_F, SC_G, SC_H, SC_J, SC_K, SC_L,
    SC_Z, SC_X, SC_C, SC_V, SC_B, SC_N, SC_M,
  );}

var
  { Init your game state here }
  gameTime: double;

  cursorLeft, cursorTop: integer;
  charBuffer: array[0..CharBufferSize - 1] of char;

  lastKeyStates: set of byte;
  currentInput: string;

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

procedure updatePromptLine;
var
  a: word;
begin
  for a:=0 to BufferWidth - 1 do
    charBuffer[a + cursorTop * BufferWidth] := ' ';

  charBuffer[cursorTop * BufferWidth] := '>';

  for a:=1 to length(currentInput) do
    charBuffer[a + cursorTop * BufferWidth + 1] := currentInput[a];

  cursorLeft := length(currentInput) + 2
end;

procedure appendCurrentInput(const c: char);
begin
  currentInput := currentInput + c;
  updatePromptLine
end;

procedure checkKeys;
var
  scancode: byte;
begin
  for scancode:=0 to 255 do
    if isKeyDown(scancode) and not (scancode in lastKeyStates) then
      { handleKeyPress(scancode); }
      case scancode of
        SC_A: appendCurrentInput('A');
        SC_B: appendCurrentInput('B');
        SC_C: appendCurrentInput('C');
        SC_D: appendCurrentInput('D');
        SC_E: appendCurrentInput('E');
        SC_F: appendCurrentInput('F');
        SC_G: appendCurrentInput('G');
        SC_H: appendCurrentInput('H');
        SC_I: appendCurrentInput('I');
        SC_J: appendCurrentInput('J');
        SC_K: appendCurrentInput('K');
        SC_L: appendCurrentInput('L');
        SC_M: appendCurrentInput('M');
        SC_N: appendCurrentInput('N');
        SC_O: appendCurrentInput('O');
        SC_P: appendCurrentInput('P');
        SC_Q: appendCurrentInput('Q');
        SC_R: appendCurrentInput('R');
        SC_S: appendCurrentInput('S');
        SC_T: appendCurrentInput('T');
        SC_U: appendCurrentInput('U');
        SC_V: appendCurrentInput('V');
        SC_W: appendCurrentInput('W');
        SC_X: appendCurrentInput('X');
        SC_Y: appendCurrentInput('Y');
        SC_Z: appendCurrentInput('Z');

        SC_BACKSPACE:
          if length(currentInput) > 0 then
            currentInput := copy(currentInput, 1, length(currentInput) - 1);
        SC_ENTER: begin
          cursorLeft := 0;
          fillchar(charBuffer[cursorTop * BufferWidth], BufferWidth, ord(' '));
          printLn('Your last input was ' + currentInput);
          currentInput := '';
          updatePromptLine
        end
      end;

  for scancode:=0 to 255 do
    if isKeyDown(scancode) then
      lastKeyStates := lastKeyStates + [scancode]
    else
      lastKeyStates := lastKeyStates - [scancode];
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

  currentInput := '';
  cls;
  printLn('Welcome to Posit-92 Wasm!');
  printLn('');
  printLn('');
  updatePromptLine
end;

procedure update; public name 'update';
begin
  updateDeltaTime;
  incrementFPS;
  updateMouse;
  
  checkKeys;

  gameTime := gameTime + dt
end;

procedure draw; public name 'draw';
var
  a, b: integer;
  
begin
  vgaCls(black);

  { Your drawing code here }
  for b:=0 to BufferHeight - 1 do
  for a:=0 to BufferWidth - 1 do
    blitChar(charBuffer[a + b * BufferWidth], a * 8, b * 8);

  if frac(getTimer) >= 0.5 then
    rectfill(
      cursorLeft * 8, cursorTop * 8,
      cursorLeft * 8 + 7, cursorTop * 8 + 7,
      LightGrey);

  { blitText('> ' + currentInput, 30, 30); }

  drawMouse;
  drawFPS;

  vgaFlush
end;

{ Requires at least 1 exported member }
exports init;

begin
{ Starting point is intentionally left empty }
end.

