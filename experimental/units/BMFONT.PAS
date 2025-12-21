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
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const text: string;
  const x, y: integer);

function measureBMFont(const glyphs: array of TBMFontGlyph; const text: string): integer;

function printBMFontCharColour(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const ch: char;
  const x, y: integer;
  const colour: longword): word;

procedure printBMFontColour(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const text: string;
  const x, y: integer;
  const colour: longword);


implementation

uses ImgRefFast, Conv, Logger;

procedure printBMFont(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph
  const text: string;
  const x, y: integer);
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

function measureBMFont(const glyphs: array of TBMFontGlyph; const text: string): integer;
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

{ Returns xadvance for the next char }
function printBMFontCharColour(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const ch: char;
  const x, y: integer;
  const colour: longword): word;
var
  charcode: byte;
  glyphIdx: integer;
  glyph: TBMFontGlyph;
  result: word;
begin
  charcode := ord(ch);
  glyphIdx := charcode - 32;

  result := 0;

  if (glyphIdx in [low(fontGlyphs)..high(fontGlyphs)]) then begin
    glyph := fontGlyphs[glyphIdx];

    sprRegionSolid(
      font.imgHandle,
      glyph.x, glyph.y,
      glyph.width, glyph.height,
      x + glyph.xoffset, y + glyph.yoffset,
      colour);

    result := glyph.xadvance
  end;

  printBMFontCharColour := result
end;

procedure printBMFontColour(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const text: string;
  const x, y: integer;
  const colour: longword);
var
  a: word;
  left: integer;
begin
  left := 0;

  for a:=1 to length(text) do
    inc(left,
      printBMFontCharColour(
        text[a],
        x + left, y,
        font, fontGlyphs, colour))
end;

end.