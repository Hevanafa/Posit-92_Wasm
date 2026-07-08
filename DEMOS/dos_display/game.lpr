library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Fonts, P92WasmHost, P92AssetRegistry,
  P92Conversions, P92FPS,
  P92Graphics,
  P92Logger,
  P92Keyboard, P92Mouse,
  P92Tex, P92TexDraw,
  P92Strings, P92Sounds, P92Timing,
  P92Version, P92WasmMemMgr, P92WasmHeap,
  VGA, Assets;

const
  BufferWidth = 40;
  BufferHeight = 25;
  CharBufferSize = BufferWidth * BufferHeight;

  BgmJingle = 1;

  {Black = $FF000000;}
  Transparent = $00000000;
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

type
  {AllowedScancodes = (
    SC_Q, SC_W, SC_E, SC_R, SC_T, SC_Y, SC_U, SC_I, SC_O, SC_P,
    SC_A, SC_S, SC_D, SC_F, SC_G, SC_H, SC_J, SC_K, SC_L,
    SC_Z, SC_X, SC_C, SC_V, SC_B, SC_N, SC_M,
  );}
  TSnowParticle = record
    active: boolean;
    x, y: double;
    vx, vy: double;
    size: integer;
    brightness: byte; { 0..255 }
  end;

var
  { Game state }
  gameTime: double;

  cursorLeft, cursorTop: integer;
  charBuffer: array[0..CharBufferSize - 1] of char;
  colourBuffer: array[0..CharBufferSize - 1] of byte;
  currentColour: byte;  { lo: fg, hi: bg }

  lastKeyStates: set of byte;
  currentInput: string;

  stringBuffer: array[0..255] of byte;
  stringBufferLength: word;

  renderSnow: boolean;
  snowflakes: array[0..99] of TSnowParticle;
  nextSpawnTick: double;

procedure queryDate; external 'env' name 'queryDate';
procedure queryTime; external 'env' name 'queryTime';


function MakeColour(const fg, bg: byte): byte;
begin
  MakeColour := (bg shl 4) or fg
end;

procedure Cls;
begin
  fillchar(charBuffer, CharBufferSize, 0);
  cursorLeft := 0;
  cursorTop := 0
end;

procedure BlitChar(const c: char; const x, y: integer; const colour: longword);
var
  charcode: byte;
  row, col: word;

  texture: PSoftwareTex;
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
  texture := GetTexturePtr(imgCGAFont);

  for b:=0 to 7 do
  for a:=0 to 7 do begin
    if (x + a >= vgaWidth) or (x + a < 0)
      or (y + b >= vgaHeight) or (y + b < 0) then continue;

    sx := col * 8 + a;
    sy := row * 8 + b;
    srcPos := (sx + sy * texture^.width) * 4;

    alpha := texture^.pixelData[srcPos + 3];
    if alpha = 255 then
      unsafePset(x + a, y + b, colour);
  end;
end;

procedure BlitCharBG(const c: char; const x, y: integer; const background: longword);
var
  charcode: byte;
  row, col: word;

  texture: PSoftwareTex;
  a, b: integer;
  sx, sy: integer;
  srcPos: longint;
  alpha: byte;
begin
  if getAlpha(background) < 255 then exit;

  charcode := ord(c);
  row := charcode div 16;
  col := charcode mod 16;

  { Inlined sprRegion
    sprRegion(imgCGAFont, col * 8, row * 8, 8, 8, x, y); }
  texture := GetTexturePtr(imgCGAFont);

  for b:=0 to 7 do
  for a:=0 to 7 do begin
    if (x + a >= vgaWidth) or (x + a < 0)
      or (y + b >= vgaHeight) or (y + b < 0) then continue;

    sx := col * 8 + a;
    sy := row * 8 + b;
    srcPos := (sx + sy * texture^.width) * 4;

    alpha := texture^.pixelData[srcPos + 3];
    if alpha = 255 then
      unsafePset(x + a, y + b, background);
  end;
end;


procedure BlitText(const text: string; const x, y: integer; const colour, background: longword);
var
  a: word;
  left: integer;
begin
  if not IsTextureSet(imgCGAFont) then begin
    writeLog('blitText: image is unset');
    exit
  end;

  left := x;

  for a:=1 to length(text) do begin
    BlitCharBG(text[a], left, y, background);
    BlitChar(text[a], left, y, colour);
    inc(left, 8)
  end;
end;

procedure ScrollBuffer;
var
  row, col: integer;
begin
  { Shift buffer upwards 1 row }
  for row:=0 to BufferHeight - 2 do
  for col:=0 to BufferWidth - 1 do begin
    charBuffer[row * BufferWidth + col] :=
      charBuffer[(row + 1) * BufferWidth + col];
      
    colourBuffer[row * BufferWidth + col] :=
      colourBuffer[(row + 1) * BufferWidth + col];
  end;
  
  fillchar(charBuffer[(BufferHeight - 1) * BufferWidth], BufferWidth, 0);
  cursorLeft := 0;
  cursorTop := BufferHeight - 1
end;

procedure IncCursorTop;
begin
  cursorLeft := 0;
  inc(cursorTop);

  if cursorTop >= BufferHeight then
    ScrollBuffer;
end;

procedure IncCursorLeft;
begin
  inc(cursorLeft);
  if cursorLeft >= BufferWidth then
    IncCursorTop;
end;

procedure textColour(const colour: byte);
begin
  currentColour := (currentColour and $F0) or (colour and $0F)
end;

procedure Print(const text: string);
var
  a: word;
begin
  for a:=1 to length(text) do begin
    charBuffer[cursorTop * BufferWidth + cursorLeft] := text[a];
    colourBuffer[cursorTop * BufferWidth + cursorLeft] := currentColour;
    IncCursorLeft
  end;
end;

procedure PrintLn(const text: string);
begin
  Print(text);
  IncCursorTop
end;

procedure UpdatePromptLine;
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

procedure HandleCommand(cmd: string);
var
  lastColour: byte;
  heapSize, freeHeapSize: longword;
  words: array[0..3] of string;
  prog: string;
begin
  cmd := trim(cmd);
  split(cmd, ' ', words);
  prog := words[0];
  
  if prog = 'CLS' then Cls
  else if prog = 'DATE' then begin
    queryDate;
    PrintLn(strPtrToString(@stringBuffer, stringBufferLength))

  end else if prog = 'TIME' then begin
    queryTime;
    PrintLn(strPtrToString(@stringBuffer, stringBufferLength))

  end else if prog = 'HELP' then begin
    lastColour := currentColour;
    textColour(9);
    PrintLn('Available commands');

    currentColour := lastColour;
    PrintLn('');
    PrintLn('  CLS  Clear screen');
    PrintLn('  DATE  Display current date');
    PrintLn('  TIME  Display current time');
    PrintLn('  HELP  Show this help');
    PrintLn('  MEM  Show memory status');
    PrintLn('  FREE  Show free memory in bytes');
    PrintLn('  DIR  Show a list of files & dirs');
    PrintLn('  SNOW  Toggle snow background');
    PrintLn('  JINGLE  Play Jingle Bells')

  end else if prog = 'MEM' then begin
    heapSize := GetHeapEnd - GetHeapStart;
    freeHeapSize := GetFreeHeapSize;

    PrintLn('Total heap: ' + i32str(heapSize div 1024) + 'KB');
    PrintLn('Used: ' + i32str(heapSize - freeHeapSize) + ' bytes');
    PrintLn('Free: ' + i32str(freeHeapSize) + ' bytes');
    PrintLn('Heap usage: ' + toFixed((heapSize - freeHeapSize) / heapSize * 100.0, 0) + '%');

  end else if prog = 'FREE' then begin
    PrintLn(i32str(GetFreeHeapSize) + ' bytes free')

  end else if prog = 'DIR' then begin
    PrintLn('Volume in drive C is POSIT92');
    PrintLn('Directory of C:\');
    PrintLn('');
    PrintLn('SECRETS  <DIR>  26-12-2025  09:02');
    PrintLn('  0 file(s)           0 bytes');
    PrintLn('  1 dir(s)      6942067 bytes free');

  end else if prog = 'SNOW' then
    renderSnow := not renderSnow

  else if prog = 'JINGLE' then begin
    if not getMusicPlaying then begin
      playMusic(BgmJingle);
      PrintLn('Playing Jingle Bells by Chiptune Arcade...')
    end;
    
  end else if prog = 'STOP' then begin
    if getMusicPlaying then begin
      stopMusic;
      PrintLn('Stopping playback...')
    end;

  end else
    PrintLn('Unknown command: ' + prog);
end;

procedure AppendCurrentInput(const c: char);
begin
  currentInput := currentInput + c;
  UpdatePromptLine
end;

procedure CheckKeys;
var
  scancode: byte;
begin
  for scancode:=0 to 255 do
    if isKeyDown(scancode) and not (scancode in lastKeyStates) then
      { handleKeyPress(scancode); }
      case scancode of
        SC_A: AppendCurrentInput('A');
        SC_B: AppendCurrentInput('B');
        SC_C: AppendCurrentInput('C');
        SC_D: AppendCurrentInput('D');
        SC_E: AppendCurrentInput('E');
        SC_F: AppendCurrentInput('F');
        SC_G: AppendCurrentInput('G');
        SC_H: AppendCurrentInput('H');
        SC_I: AppendCurrentInput('I');
        SC_J: AppendCurrentInput('J');
        SC_K: AppendCurrentInput('K');
        SC_L: AppendCurrentInput('L');
        SC_M: AppendCurrentInput('M');
        SC_N: AppendCurrentInput('N');
        SC_O: AppendCurrentInput('O');
        SC_P: AppendCurrentInput('P');
        SC_Q: AppendCurrentInput('Q');
        SC_R: AppendCurrentInput('R');
        SC_S: AppendCurrentInput('S');
        SC_T: AppendCurrentInput('T');
        SC_U: AppendCurrentInput('U');
        SC_V: AppendCurrentInput('V');
        SC_W: AppendCurrentInput('W');
        SC_X: AppendCurrentInput('X');
        SC_Y: AppendCurrentInput('Y');
        SC_Z: AppendCurrentInput('Z');
        SC_SPACE: AppendCurrentInput(' ');

        SC_1: AppendCurrentInput('1');
        SC_2: AppendCurrentInput('2');
        SC_3: AppendCurrentInput('3');
        SC_4: AppendCurrentInput('4');
        SC_5: AppendCurrentInput('5');
        SC_6: AppendCurrentInput('6');
        SC_7: AppendCurrentInput('7');
        SC_8: AppendCurrentInput('8');
        SC_9: AppendCurrentInput('9');
        SC_0: AppendCurrentInput('0');

        SC_BACKSPACE:
          if length(currentInput) > 0 then begin
            currentInput := copy(currentInput, 1, length(currentInput) - 1);
            UpdatePromptLine
          end;

        SC_ENTER: begin
          IncCursorTop;
          HandleCommand(currentInput);
          currentInput := '';
          UpdatePromptLine
        end
      end;

  for scancode:=0 to 255 do
    if isKeyDown(scancode) then
      lastKeyStates := lastKeyStates + [scancode]
    else
      lastKeyStates := lastKeyStates - [scancode];
end;


procedure BrawFPS;
begin
  BlitText(
    'FPS:' + i32str(getLastFPS),
    240, 0,
    palette[$0E], transparent);
end;

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure SpawnSnowflake;
var
  a: word;
  idx: integer;
begin
  idx := -1;

  for a:=0 to high(snowflakes) do
    if not snowflakes[a].active then begin
      idx := a;
      break
    end;

  if idx < 0 then exit;

  snowflakes[idx].active := true;
  snowflakes[idx].x := random(vgaWidth);
  snowflakes[idx].y := -10;
  snowflakes[idx].vx := 0;
  snowflakes[idx].vy := 30.0 + random(70);  { Pixels per second }
  snowflakes[idx].size := 1 + random(3);
  snowflakes[idx].brightness := trunc((0.5 + random / 2) * 255)
end;



procedure OnPreload;
begin
  { TODO: Load the assets }
end;

procedure OnReady;
var
  a: word;
  heapSize, freeHeapSize: longword;
begin
  hideCursor;

  { Initialise game state here }
  gameTime := 0.0;

  renderSnow := false;
  for a:=0 to high(snowflakes) do
    snowflakes[a].active := false;

  currentInput := '';
  currentColour := MakeColour(7, 0);

  { Welcome message }
  Cls;
  PrintLn('');
  PrintLn('Posit-92 Wasm ' + Posit92_Version);
  PrintLn('(C) 2025 Hevanafa');

  heapSize := GetHeapEnd - GetHeapStart;
  freeHeapSize := GetFreeHeapSize;
  PrintLn(i32str(heapSize div 1024) + 'KB OK  ' + i32str(freeHeapSize) + ' BYTES FREE');

  PrintLn('');
  PrintLn('Type HELP for available commands');
  PrintLn('');
  UpdatePromptLine
end;

procedure InitDefaultFont;
var
  a, b: word;
  texture: PSoftwareTex;
begin
  if not IsTextureSet(imgCGAFont) then begin
    writeLog('initDefaultFont: image is unset');
    exit
  end;

  texture := GetTexturePtr(imgCGAFont);

  for b:=0 to GetTextureHeight(imgCGAFont) - 1 do
  for a:=0 to GetTextureWidth(imgCGAFont) - 1 do
    if unsafeSprGetAlpha(texture, a, b) = 255 then
      unsafeSprPset(texture, a, b, LightGrey);
end;

procedure Update;
var
  a: word;
  drift: double;
begin
  CheckKeys;

  if renderSnow then begin
    for a:=0 to high(snowflakes) do begin
      if not snowflakes[a].active then continue;

      with snowflakes[a] do begin
        y := y + vy * DeltaTime;

        drift := sin(y * 0.1 + getTimer * 2.0) * 12.0;
        x := x + (vx + drift) * DeltaTime;

        if y >= vgaHeight then
          active := false;
      end;
    end;

    if getTimer >= nextSpawnTick then begin
      nextSpawnTick := getTimer + 0.1;
      SpawnSnowflake;
    end;
  end;

  if getMusicPlaying and (getMusicTime >= getMusicDuration - 0.05) then
    stopMusic;

  gameTime := gameTime + DeltaTime;
end;

procedure Draw;
var
  a, b: integer;
  c: char;
  grey: byte;
  timeOffset: double;
begin
  vgaCls(black);

  if renderSnow then begin
    { Render snowflakes }
    for a:=0 to high(snowflakes) do begin
      if not snowflakes[a].active then continue;

      if snowflakes[a].size = 1 then begin
        with snowflakes[a] do
          pset(
            trunc(x), trunc(y),
            $FF000000 or (brightness shl 16) or (brightness shl 8) or brightness);
      end else begin
        with snowflakes[a] do
          circfill(
            trunc(x), trunc(y), size,
            $FF000000 or (brightness shl 16) or (brightness shl 8) or brightness);
      end;
    end;
  end else begin
    { Render scanlines }
    timeOffset := frac(getTimer) * 2 * PI;
    for b:=0 to vgaHeight-1 do begin
      grey := trunc((sin(b - timeOffset) + 1.0) * 20.0);  { * 0.15 * 255 / 2.0, rounded up }
      hline(0, vgaWidth-1, b, $FF000000 or (grey shl 16) or (grey shl 8) or grey)
    end;
  end;

  { Your drawing code here }
  for b:=0 to BufferHeight - 1 do
  for a:=0 to BufferWidth - 1 do begin
    c := charBuffer[a + b * BufferWidth];
    if (c = ' ') or (c = chr(0)) then continue;

    BlitChar(c,
      a * 8, b * 8,
      palette[colourBuffer[a + b * BufferWidth] and $0F])
  end;

  { Blinking cursor }
  if frac(getTimer) >= 0.5 then
    rectfill(
      cursorLeft * 8, cursorTop * 8,
      cursorLeft * 8 + 7, cursorTop * 8 + 7,
      LightGrey);

  { BlitText('> ' + currentInput, 30, 30); }

  DrawMouse;
  BrawFPS;
end;

{ Requires at least 1 exported member }
exports
  InitDefaultFont,
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

