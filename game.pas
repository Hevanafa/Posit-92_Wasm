library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Graphics, Logger, VGA;

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

function strPtrToString(const textPtr: pointer; const textLen: word): string;
var
  text: string;
  a: integer;
  charPtr: ^byte;
begin
  setLength(text, textLen);
  charPtr := textPtr;
  for a:=1 to textLen do begin
    text[a] := char(charPtr^);
    inc(charPtr)
  end;

  strPtrToString := text
end;

procedure debugStringBuffer; public name 'debugStringBuffer';
var
  a: word;
begin
  writeLog('First 20 bytes of stringBuffer');

  for a:=0 to 19 do
    writeLogI32(stringBuffer[a]);
end;

procedure printDefault(const textPtr: pointer; const textLen: integer; const x, y: integer); public name 'printDefault';
var
  text: string;
begin
  text := strPtrToString(textPtr, textLen);
  writeLog(text);
  printBMFont(text, x, y, _defaultFont, _defaultFontGlyphs)
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
  spr;

begin
{ Starting point is intentionally left empty }
end.

