unit BMFont;

interface

type
  TBMFontGlyph = record
    id: word;
    x, y, width, height: word;
    xoffset, yoffset: integer;
    xadvance: integer;
  end;
  TBMFont = record
    face: string;
    filename: string;
    lineHeight: word;
    imgHandle: longword;
  end;

procedure printBMFont(
  const text: string;
  const x, y: integer;
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph);

implementation

uses Bitmap;

procedure printBMFont(
  const text: string;
  const x, y: integer;
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph);
var
  a: word;
  ch: char;
  charcode: byte;
  left: integer;
begin
  left := 0;

  for a:=1 to length(text) do begin
    ch := text[a];
    charcode := ord(ch);

    if (charcode < low(fontGlyphs)) or (charcode > high(fontGlyphs)) then
      continue;
    
    sprRegion(
      font.imgHandle,
      fontGlyphs[charcode].x, fontGlyphs[charcode].y,
      fontGlyphs[charcode].width, fontGlyphs[charcode].height,
      x + left + fontGlyphs[charcode].xoffset, y + fontGlyphs[charcode].yoffset);

    inc(left, fontGlyphs[charcode].xadvance)
  end;
end;

end.