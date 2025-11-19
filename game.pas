library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, Keyboard, Logger, Mouse,
  Timing, VGA;

const
  SC_ESC = $01;

var
  lastEsc: boolean;
  _defaultFont: TBMFont;
  _defaultFontGlyphs: array[32..126] of TBMFontGlyph;
  stringBuffer: array[0..255] of byte;

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

procedure debugMouse;
begin
  printDefault('Mouse: {x:' + i32str(mouseX) + ', y:' + i32str(mouseY) + '}', 0, 0);
  printDefault('Button: ' + i32str(integer(mouseButton)), 0, 8);
end;

procedure signalDone; external 'env' name 'signalDone';


procedure init;
begin
  initBuffer;
  initDeltaTime;
  initFPSCounter;
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
end;

procedure draw;
var
  image: PBitmap;
begin
  cls($FF6495ED);

  printDefault('getTimer: ' + f32str(getTimer), 160, 10);

  { printDefault('Hello from POSIT-92!', 10, 10); }
  debugMouse;

  { gasoline maid }
  image := getImagePtr(1);
  sprBlend(1, (vgaWidth - image^.width) div 2, (vgaHeight - image^.height) div 2);

  drawFPS;

  flush
end;


exports
  { VGA }
  initBuffer,
  getSurface,
  cls,
  pset,

  { BITMAP }
  loadImageHandle,
  getImagePtr,
  spr,

  { Main game loop }
  init,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

