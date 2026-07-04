unit P92Fonts;

interface

uses P92BMFont;

procedure LoadDefaultFont; public name 'LoadDefaultFont';

function DefaultFontPtr: PBMFont;
function DefaultFontGlyphsPtr: PBMFontGlyph;

procedure PrintDefault(const text: string; const x, y: integer);
procedure PrintDefaultCentred(const text: string; const cx, y: integer);
function MeasureDefault(const text: string): word;


implementation

uses P92AssetRegistry;

var
  defaultFont: TBMFont;
  defaultFontGlyphs: array[32..126] of TBMFontGlyph;

procedure LoadDefaultFont;
begin
  RequestBMFont(
    'assets/fonts/nokia_cellphone_fc_8.txt',
    DefaultFontPtr, DefaultFontGlyphsPtr)
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

end.

