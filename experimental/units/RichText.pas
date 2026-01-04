unit RichText;

interface

procedure rtfSetRegularFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);

procedure TestRichTextLabel(
  const text: string;
  const x, y: integer;
  const colorTable: array of longword);


implementation

uses BMFont;

var
  isFontSet: boolean;
  regularFont: TBMFont;
  regularFontGlyphs: array[32..126] of TBMFontGlyph;

procedure rtfSetRegularFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
begin
  isFontSet := true;
  activeFont := font;

  for a := 32 to 126 do
    activeFontGlyphs[a] := glyphs[a - 32];
end;

procedure TestRichTextLabel(
  const text: string;
  const x, y: integer;
  const colorTable: array of longword);
var
  bold, italic: boolean;
  currentColour: cardinal;
begin
  if not isFontSet then panicHalt('TestRichTextLabel: font is unset!');


end;

end.
