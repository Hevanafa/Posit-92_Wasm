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

uses Bitmap, Logger;

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

{
  writeLogI32(font.lineHeight);
  writeLogI32(font.imgHandle); } { 0 ?? }

  writeLog('printBMFont low & high:');
  writeLogI32(low(fontGlyphs));
  writeLogI32(high(fontGlyphs));

  for a:=1 to length(text) do begin
    ch := text[a];
    charcode := ord(ch);

    { Assuming the starting charcode is always 32 }
    dec(charcode, 32);

    if (charcode < low(fontGlyphs)) or (charcode > high(fontGlyphs)) then
      continue;
    
    writeLogI32(charcode);
    writeLogI32(fontGlyphs[charcode].x);
    writeLogI32(fontGlyphs[charcode].y);

    sprRegion(
      font.imgHandle,
      fontGlyphs[charcode].x, fontGlyphs[charcode].y,
      fontGlyphs[charcode].width, fontGlyphs[charcode].height,
      x + left + fontGlyphs[charcode].xoffset, y + fontGlyphs[charcode].yoffset);

    inc(left, fontGlyphs[charcode].xadvance)
  end;
end;

end.