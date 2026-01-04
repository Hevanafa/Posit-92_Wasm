unit RichText;

interface

uses BMFont;

procedure rtfSetRegularFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
procedure rtfSetBoldFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);

procedure TestRichTextLabel(
  const text: string;
  const x, y: integer;
  const colourTable: array of longword);


implementation

uses Panic;

var
  isFontSet: boolean;
  regularFont, boldFont: TBMFont;
  regularFontGlyphs, boldFontGlyphs: array[32..126] of TBMFontGlyph;

procedure rtfSetRegularFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
var
  a: word;
begin
  isFontSet := true;
  regularFont := font;
  for a := 32 to 126 do regularFontGlyphs[a] := glyphs[a - 32];
end;

procedure rtfSetBoldFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
var
  a: word;
begin
  isFontSet := true;
  boldFont := font;
  for a := 32 to 126 do boldFontGlyphs[a] := glyphs[a - 32];
end;


procedure TestRichTextLabel(
  const text: string;
  const x, y: integer;
  const colourTable: array of longword);
var
  bold, italic: boolean;
  colour: cardinal;
begin
  if not isFontSet then panicHalt('TestRichTextLabel: font is unset!');

  bold := false;
  italic := false;
  colour := colourTable[0];

  printBMFontColour(regularFont, regularFontGlyphs, text, x, y, colour);
  printBMFontColour(boldFont, boldFontGlyphs, text, x, y + boldFont.lineHeight, colour);

  colour := colourTable[1];
  printBMFontColour(regularFont, regularFontGlyphs, text, x, y + regularFont.lineHeight * 2, colour);

end;

end.
