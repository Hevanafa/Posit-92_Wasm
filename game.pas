library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Graphics, Logger, VGA;

var
  _defaultFont: TBMFont;
  _defaultFontGlyphs: array[32..126] of TBMFontGlyph;

function defaultFont: pointer;
begin
  defaultFont := @_defaultFont
end;

function defaultFontGlyphs: pointer;
begin
  defaultFontGlyphs := @_defaultFontGlyphs
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

