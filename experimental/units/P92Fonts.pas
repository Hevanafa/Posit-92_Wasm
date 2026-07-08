unit P92Fonts;

interface

uses P92BMFont;

procedure LoadDefaultFont;

function DefaultFontPtr: PBMFont;
function DefaultFontGlyphsPtr: PBMFontGlyph;

procedure PrintDefault(const text: string; const x, y: integer);
procedure PrintDefaultCentred(const text: string; const cx, y: integer);
function MeasureDefault(const text: string): word;

function PrintCharColour(const ch: char; const x, y: integer; const colour: longword): word;


implementation

uses P92AssetRegistry;

var
  defaultFont: TBMFont;
  defaultFontGlyphs: array[0..255] of TBMFontGlyph;

procedure LoadDefaultFont;
var
  a: word;
begin
  defaultFont := default(TBMFont);

  for a:=0 to high(defaultFontGlyphs) do
    defaultFontGlyphs[a] := default(TBMFontGlyph);

  RequestBMFont(
    'assets/fonts/nokia_cellphone_fc_8.txt',
    DefaultFontPtr, DefaultFontGlyphsPtr);
end;

function DefaultFontPtr: PBMFont;
begin
  DefaultFontPtr := @defaultFont
end;

function DefaultFontGlyphsPtr: PBMFontGlyph;
begin
  DefaultFontGlyphsPtr := @defaultFontGlyphs
end;

procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(defaultFont, defaultFontGlyphs, text, x, y)
end;

procedure PrintDefaultCentred(const text: string; const cx, y: integer);
var
  w: word;
begin
  w := MeasureDefault(text);
  PrintDefault(text, cx - w div 2, y)
end;

function MeasureDefault(const text: string): word;
begin
  MeasureDefault := MeasureBMFont(defaultFont, defaultFontGlyphs, text)
end;

{ Returns the width of the glyph }
function PrintCharColour(const ch: char; const x, y: integer; const colour: longword): word;
begin
  PrintCharColour := PrintBMFontCharColour(
    defaultFont, defaultFontGlyphs, ch, x, y, colour)
end;

end.

