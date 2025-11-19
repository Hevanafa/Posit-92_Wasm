unit BMFont;

interface

type
  { PBMFontGlyph = ^TBMFontGlyph; }
  TBMFontGlyph = record
    id: word;
    x, y, width, height: word;
    xoffset, yoffset: integer;
    xadvance: integer;
  end;
  TBMFont = packed record
    face: string[15];  { 16 bytes }
    filename: string[63];  { 64 bytes }
    lineHeight: word;  { 2 bytes }
    { (N/A with packed record) + automatic 2-byte padding }
    imgHandle: longint;  { 84th byte }
  end;

procedure printBMFont(
  const text: string;
  const x, y: integer;
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph);


implementation

uses Bitmap, Conv, Logger;

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
  glyph: TBMFontGlyph;
begin
  left := 0;

  // writeLog('lineHeight: ' + i32str(font.lineHeight));
  // writeLog('imgHandle: ' + i32str(font.imgHandle));
  writelog('low: ' + i32str(low(fontGlyphs)) + ', high: ' + i32str(high(fontGlyphs)));

  for a:=1 to length(text) do begin
    ch := text[a];
    charcode := ord(ch);

    { writeLog('charcode: ' + i32str(charcode)); }

    { Assuming the starting charcode is always 32 }
    dec(charcode, 32);

    { writeLog('charcode after dec: ' + i32str(charcode)); }

    { if (low(fontGlyphs) <= charcode) and (charcode <= high(fontGlyphs)) then begin }
    if (charcode in [low(fontGlyphs)..high(fontGlyphs)]) then begin
      writeLogI32(charcode);
      writeLogI32(fontGlyphs[charcode].x);
      writeLogI32(fontGlyphs[charcode].y);

      glyph := fontGlyphs[charcode];

      sprRegionBlend(
        font.imgHandle,
        glyph.x, glyph.y,
        glyph.width, glyph.height,
        x + left + glyph.xoffset, y + glyph.yoffset);

      inc(left, glyph.xadvance)
    end;
  end;
end;

end.