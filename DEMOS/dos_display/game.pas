library Game;

{$Mode TP}
{$B-}

uses
  Conv, FPS, Graphics, Loading, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Strings, Timing, WasmMemMgr, WasmHeap,
  Version, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_BACKSPACE = $0E;
  SC_ENTER = $1C;

  SC_1 = $02;
  SC_2 = $03;
  SC_3 = $04;
  SC_4 = $05;
  SC_5 = $06;
  SC_6 = $07;
  SC_7 = $08;
  SC_8 = $09;
  SC_9 = $0A;
  SC_0 = $0B;

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

  BufferWidth = 40;
  BufferHeight = 25;
  CharBufferSize = BufferWidth * BufferHeight;

  {Black = $FF000000;}
  Black = $FF202020;
  LightGrey = $FFAAAAAA;
  White = $FFFFFFFF;

  Palette: array of longword = (
    $FF000000,
    $FF0000AA,
    $FF00AA00,
    $FF00AAAA,
    $FFAA0000,
    $FFAA00AA,
    $FFAA5500,
    $FFAAAAAA,

    $FF555555,
    $FF5555FF,
    $FF55FF55,
    $FF55FFFF,
    $FFFF5555,
    $FFFF55FF,
    $FFFFFF55,
    $FFFFFFFF
  );

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
  colourBuffer: array[0..CharBufferSize - 1] of byte;
  currentColour: byte;  { lo: fg, hi: bg }

  lastKeyStates: set of byte;
  currentInput: string;

  stringBuffer: array[0..255] of byte;
  stringBufferLength: word;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure queryDate; external 'env' name 'queryDate';
procedure queryTime; external 'env' name 'queryTime';

function getStringBuffer: PByte; public name 'getStringBuffer';
begin
  getStringBuffer := @stringBuffer
end;

procedure setStringBufferLength(const value: word); public name 'setStringBufferLength';
begin
  stringBufferLength := value
end;


function makeColour(const fg, bg: byte): byte;
begin
  makeColour := (bg shl 4) or fg
end;

procedure cls;
begin
  fillchar(charBuffer, CharBufferSize, 0);
  cursorLeft := 0;
  cursorTop := 0
end;

procedure blitChar(const c: char; const x, y: integer; const colour: longword);
var
  charcode: byte;
  row, col: word;

  image: PImageRef;
  a, b: integer;
  sx, sy: integer;
  srcPos: longint;
  alpha: byte;
begin
  charcode := ord(c);
  row := charcode div 16;
  col := charcode mod 16;

  { Inlined sprRegion
    sprRegion(imgCGAFont, col * 8, row * 8, 8, 8, x, y); }
  image := getImagePtr(imgCGAFont);

  for b:=0 to 7 do
  for a:=0 to 7 do begin
    if (x + a >= vgaWidth) or (x + a < 0)
      or (y + b >= vgaHeight) or (y + b < 0) then continue;

    sx := col * 8 + a;
    sy := row * 8 + b;
    srcPos := (sx + sy * image^.width) * 4;

    alpha := image^.dataPtr[srcPos + 3];
    if alpha = 255 then
      unsafePset(x + a, y + b, colour);
  end;
end;

procedure blitText(const text: string; const x, y: integer; const colour: longword);
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
    blitChar(text[a], left, y, colour);
    inc(left, 8)
  end;
end;

procedure scrollBuffer;
var
  row, col: integer;
begin
  for row:=0 to BufferHeight - 2 do
  for col:=0 to BufferWidth - 1 do
    charBuffer[row * BufferWidth + col] :=
      charBuffer[(row + 1) * BufferWidth + col];
  
  fillchar(charBuffer[(BufferHeight - 1) * BufferWidth], BufferWidth, 0);
  cursorLeft := 0;
  cursorTop := BufferHeight - 1
end;

procedure incCursorTop;
begin
  cursorLeft := 0;
  inc(cursorTop);

  if cursorTop >= BufferHeight then
    scrollBuffer;
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
    colourBuffer[cursorTop * BufferWidth + cursorLeft] := currentColour;
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
  fillchar(charBuffer[cursorTop * BufferWidth], BufferWidth, 0);
  fillchar(colourBuffer[cursorTop * BufferWidth], BufferWidth, currentColour);

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
        SC_SPACE: appendCurrentInput(' ');

        SC_1: appendCurrentInput('1');
        SC_2: appendCurrentInput('2');
        SC_3: appendCurrentInput('3');
        SC_4: appendCurrentInput('4');
        SC_5: appendCurrentInput('5');
        SC_6: appendCurrentInput('6');
        SC_7: appendCurrentInput('7');
        SC_8: appendCurrentInput('8');
        SC_9: appendCurrentInput('9');
        SC_0: appendCurrentInput('0');

        SC_BACKSPACE:
          if length(currentInput) > 0 then begin
            currentInput := copy(currentInput, 1, length(currentInput) - 1);
            updatePromptLine
          end;

        SC_ENTER: begin
          incCursorTop;
          currentInput := trim(currentInput);
          
          if currentInput = 'CLS' then cls
          else if currentInput = 'DATE' then begin
            queryDate;
            printLn(strPtrToString(@stringBuffer, stringBufferLength))
          end else if currentInput = 'TIME' then begin
            queryTime;
            printLn(strPtrToString(@stringBuffer, stringBufferLength))
          end else
            printLn('Unknown command: ' + currentInput);

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
  blitText('FPS:' + i32str(getLastFPS), 240, 0, palette[$0E]);
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
      unsafeSprPset(image, a, b, LightGrey);
end;

procedure afterInit; public name 'afterInit';
var
  heapSize: longword;
begin
  { Initialise game state here }
  hideCursor;

  currentInput := '';
  currentColour := makeColour(7, 0);

  { Welcome message }
  cls;
  printLn('');
  printLn('Posit-92 Wasm ' + Posit92_Version);
  printLn('(C) 2025 Hevanafa');

  heapSize := heapEnd - heapStart;
  printLn(i32str(heapSize div 1024) + 'KB RAM OK');

  printLn('');
  printLn('Type HELP for available commands');
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
  c: char;
  grey: byte;
  timeOffset: double;
begin
  vgaCls(black);

  { Render scanlines }
  timeOffset := frac(getTimer) * 2 * PI;
  for b:=0 to vgaHeight-1 do begin
    grey := trunc((sin(b - timeOffset) + 1.0) * 20.0);  { * 0.15 * 255 / 2.0, rounded up }
    hline(0, vgaWidth-1, b, $FF000000 or (grey shl 16) or (grey shl 8) or grey)
  end;

  { Your drawing code here }
  for b:=0 to BufferHeight - 1 do
  for a:=0 to BufferWidth - 1 do begin
    c := charBuffer[a + b * BufferWidth];
    if (c = ' ') or (c = chr(0)) then continue;

    blitChar(c,
      a * 8, b * 8,
      palette[lo(colourBuffer[a + b * BufferWidth])])
  end;

  { Blinking cursor }
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

