library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Graphics, Logger, VGA;

var
  _defaultFont: TBMFont;
  _defaultFontGlyphs: array[32..126] of TBMFontGlyph;


function defaultFontPtr: pointer; public name 'defaultFontPtr';
begin
  defaultFontPtr := @_defaultFont
end;

function defaultFontGlyphsPtr: pointer; public name 'defaultFontGlyphsPtr';
begin
  defaultFontGlyphsPtr := @_defaultFontGlyphs
end;

procedure printDefault(const text: string; const x, y: integer); public name 'printDefault';
begin
  writeLog('printDefault low & high:');
  writeLogI32(low(_defaultFontGlyphs));
  writeLogI32(high(_defaultFontGlyphs));

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

