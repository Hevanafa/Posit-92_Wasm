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

{ strPtrToPString }
function pascalStringPtr(const textPtr: pointer; const textLen: word): PString; public name 'pascalStringPtr';
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

  pascalStringPtr := @text
end;

procedure debugPString(const textPtr: PString); public name 'debugPString';
var
  a: integer;
  text: string;
begin
  
end;

{ TODO: interop text from JS }
procedure printDefault(const text: PString; const x, y: integer); public name 'printDefault';
begin
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

