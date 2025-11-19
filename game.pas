library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, Logger, Timing, VGA;

var
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
procedure printDefault(const textPtr: pointer; const textLen: integer; const x, y: integer); public name 'printDefault';
var
  text: string;
begin
  text := strPtrToString(textPtr, textLen);
  { writeLog(text); }
  printBMFont(text, x, y, _defaultFont, _defaultFontGlyphs)
end;

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0, $00);
end;


procedure init;
begin
  initDeltaTime;
  initFPSCounter;
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  { Your update logic here }
end;

procedure draw;
var
  image: PBitmap;
begin
  cls($FF6495ED);

  printBMFont('getTimer: ' + f32str(getTimer), 160, 10, _defaultFont, _defaultFontGlyphs);

  printBMFont('Hello from POSIT-92!', 10, 10, _defaultFont, _defaultFontGlyphs);

  { gasoline maid }
  image := getImagePtr(1);
  sprBlend(1, (vgaWidth - image^.width) div 2, (vgaHeight - image^.height) div 2);
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

  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

