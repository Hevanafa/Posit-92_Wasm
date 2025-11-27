{
  BMFont unit
  Part of POSIT-92 Framework
  This unit contains only a subset of the DOS version
}

unit BMFont;

{$Mode TP}
{$B-}  { Enable boolean short-circuiting }

interface

type
  PBMFontGlyph = ^TBMFontGlyph;
  TBMFontGlyph = record
    id: word;
    x, y, width, height: word;
    xoffset, yoffset: integer;
    xadvance: integer;
  end;

  PBMFont = ^TBMFont;
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

function measureBMFont(const text: string; const glyphs: array of TBMFontGlyph): integer;


implementation

uses SprFast, Conv, Logger;

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

  glyphIdx: integer;
  glyph: TBMFontGlyph;
begin
  left := 0;

  for a:=1 to length(text) do begin
    ch := text[a];
    charcode := ord(ch);

    { Assuming the starting charcode is always 32 }
    glyphIdx := charcode - 32;

    if (glyphIdx in [low(fontGlyphs)..high(fontGlyphs)]) then begin
      glyph := fontGlyphs[glyphIdx];

      sprRegion(
        font.imgHandle,
        glyph.x, glyph.y,
        glyph.width, glyph.height,
        x + left + glyph.xoffset, y + glyph.yoffset);

      inc(left, glyph.xadvance)
    end;
  end;
end;

function measureBMFont(const text: string; const glyphs: array of TBMFontGlyph): integer;
var
  a, result: word;
  glyphIdx: integer;
  charcode: byte;
begin
  result := 0;

  for a:=1 to length(text) do begin
    charcode := ord(text[a]);

    { Assuming the starting charcode is always 32 }
    glyphIdx := charcode - 32;

    if (glyphIdx in [low(glyphs)..high(glyphs)]) then begin
      inc(result, glyphs[glyphIdx].xadvance)
    end;
  end;

  measureBMFont := result
end;

end.