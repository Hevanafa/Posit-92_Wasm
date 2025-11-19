library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, Keyboard, Logger, Mouse,
  Panic, Sounds, Timing, VGA;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  { Must be the same with JS code }
  SfxCoin = 1;
  BgmMain = 11;

var
  lastEsc, lastSpacebar: boolean;

  stringBuffer: array[0..255] of byte;

  { for use in loadBMFont }
  _defaultFont: TBMFont;
  _defaultFontGlyphs: array[32..126] of TBMFontGlyph;

  imgCursor, imgGasolineMaid: longint;

  lastLeftButton: boolean;
  clicks: word;

procedure signalDone; external 'env' name 'signalDone';

function getStringBuffer: pointer; public name 'getStringBuffer';
begin
  getStringBuffer := @stringBuffer
end;

function defaultFontPtr: pointer; public name 'defaultFontPtr';
begin
  defaultFontPtr := @_defaultFont
end;

function defaultFontGlyphsPtr: pointer; public name 'defaultFontGlyphsPtr';
begin
  defaultFontGlyphsPtr := @_defaultFontGlyphs
end;

procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
begin
  imgCursor := imgHandle
end;

procedure setImgGasolineMaid(const imgHandle: longint); public name 'setImgGasolineMaid';
begin
  imgGasolineMaid := imgHandle
end;

procedure debugStringBuffer; public name 'debugStringBuffer';
var
  a: word;
begin
  writeLog('First 20 bytes of stringBuffer');

  for a:=0 to 19 do
    writeLogI32(stringBuffer[a]);
end;

{ Requires BMFont }
procedure printDefault(const text: string; const x, y: integer);
begin
  { writelog('printDefault A'); }
  printBMFont(text, x, y, _defaultFont, _defaultFontGlyphs)
end;

{ Requires BMFont
  for use with JS }
procedure printDefault(const textPtr: pointer; const textLen: integer; const x, y: integer); public name 'printDefault';
var
  text: string;
begin
  { writeLog('printDefault B'); }
  text := strPtrToString(textPtr, textLen);
  { writeLog(text); }
  printBMFont(text, x, y, _defaultFont, _defaultFontGlyphs)
end;

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  sprBlend(imgCursor, mouseX, mouseY)
end;

procedure debugMouse;
begin
  printDefault('Mouse: {x:' + i32str(mouseX) + ', y:' + i32str(mouseY) + '}', 0, 0);
  printDefault('Button: ' + i32str(integer(mouseButton)), 0, 8);
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
  
  playMusic(BgmMain);
  setMusicVolume(0.5)
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

  if lastSpacebar <> isKeyDown(SC_SPACE) then begin
    lastSpacebar := isKeyDown(SC_SPACE);

    if lastSpacebar then
      playSound(SfxCoin);
  end;

  if lastLeftButton <> (0 <> mouseButton and 1) then begin
    lastLeftButton := (0 <> mouseButton and 1);

    if lastLeftButton then inc(clicks);
  end;
end;

procedure draw;
var
  image: PBitmap;
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  image := getImagePtr(imgGasolineMaid);
  sprBlend(imgGasolineMaid, (vgaWidth - image^.width) div 2, (vgaHeight - image^.height) div 2);

  s := 'Clicks: ' + i32str(clicks);
  w := measureBMFont(s, _defaultFontGlyphs);
  printDefault(s, (vgaWidth - w) div 2, 160);

  drawMouse;

  debugMouse;
  drawFPS;

  flush
end;

exports
  { Main game loop }
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

