{
  BMFont
  Part of Posit-92 game engine
  By Hevanafa
}

unit P92BMFont;

{$Mode ObjFPC}
{$H+}{$J-}

interface

type
  PBMFontGlyphLegacy = ^TBMFontGlyphLegacy;
  TBMFontGlyphLegacy = record
    id: word;
    x, y, width, height: word;
    xoffset, yoffset: smallint;
    xadvance: smallint;
  end;

  PBMFontLegacy = ^TBMFontLegacy;
  TBMFontLegacy = record
    face: string[15];  { 16 bytes ShortString }
    filename: string[63];  { 64 bytes }
    lineHeight: word;  { 2 bytes }
    spacing: array[0..1] of byte; { x, y }
    texHandle: longint;  { 84th byte }
  end;

{ This procedure creates a new ImgRef instance }
procedure CloneBMFont(
  const srcFont: TBMFontLegacy; const srcFontGlyphs: array of TBMFontGlyphLegacy;
  var destFont: TBMFontLegacy; var destFontGlyphs: array of TBMFontGlyphLegacy);

procedure FreeBMFont(
  var font: TBMFontLegacy;
  var fontGlyphs: array of TBMFontGlyphLegacy;
  const freeImgHandle: boolean);

procedure PrintBMFont(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyphLegacy;
  const text: string;
  const x, y: smallint);

function MeasureBMFont(
  const font: TBMFontLegacy;
  const glyphs: array of TBMFontGlyphLegacy;
  const text: string): smallint;

function PrintBMFontCharColour(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyphLegacy;
  const ch: char;
  const x, y: smallint;
  const colour: longword): word;

procedure PrintBMFontColour(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyphLegacy;
  const text: string;
  const x, y: smallint;
  const colour: longword);

function PrintBMFontCharToDest(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyphLegacy;
  const destHandle: longint;
  const ch: char;
  const x, y: smallint): smallint;

procedure PrintBMFontToDest(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyphLegacy;
  const destHandle: longint;
  const text: string;
  const x, y: smallint);


implementation

uses
  P92Conversions, P92Logger,
  P92Tex, P92TexDraw;

{ Returns glyph.xadvance }
function PrintBMFontChar(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyphLegacy;
  const ch: char;
  const x, y: smallint): smallint;
var
  charcode: byte;
  glyphIdx: smallint;
  glyph: TBMFontGlyphLegacy;
begin
  charcode := ord(ch);

  glyphIdx := charcode;

  if (glyphIdx in [low(fontGlyphs)..high(fontGlyphs)]) then begin
    glyph := fontGlyphs[glyphIdx];

    SprRegion(
      font.texHandle,
      glyph.x, glyph.y,
      glyph.width, glyph.height,
      x + glyph.xoffset, y + glyph.yoffset);
    
    PrintBMFontChar := glyph.xadvance
  end else
    PrintBMFontChar := 0;
end;

procedure CloneBMFont(
  const srcFont: TBMFontLegacy; const srcFontGlyphs: array of TBMFontGlyphLegacy;
  var destFont: TBMFontLegacy; var destFontGlyphs: array of TBMFontGlyphLegacy);
var
  a: word;
begin
  destFont := srcFont;

  for a:=0 to high(srcFontGlyphs) do
    destFontGlyphs[a] := srcFontGlyphs[a];

  destFont.texHandle := CopyTexture(srcFont.texHandle)
end;

procedure FreeBMFont(
  var font: TBMFontLegacy;
  var fontGlyphs: array of TBMFontGlyphLegacy;
  const freeImgHandle: boolean);
var
  a: Word;
begin
  if freeImgHandle then
    FreeTexture(font.texHandle);

  fillchar(font, sizeof(TBMFontLegacy), 0);
  for a:=0 to high(fontGlyphs) do
    fillchar(fontGlyphs[a], sizeof(TBMFontGlyphLegacy), 0);
end;

procedure PrintBMFont(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyphLegacy;
  const text: string;
  const x, y: smallint);
var
  a: word;
  ch: char;
  left, step: smallint;
begin
  left := 0;

  for a:=1 to length(text) do begin
    ch := text[a];
    step := PrintBMFontChar(font, fontGlyphs, ch, x + left, y);

    if a < length(text) then
      inc(left, step + font.spacing[0])
    else
      inc(left, step);
  end;
end;


function MeasureBMFont(
  const font: TBMFontLegacy;
  const glyphs: array of TBMFontGlyphLegacy;
  const text: string): smallint;
var
  a: word;
  glyphIdx: smallint;
  charcode: byte;
begin
  MeasureBMFont := 0;

  for a:=1 to length(text) do begin
    charcode := ord(text[a]);

    glyphIdx := charcode;

    if (glyphIdx in [low(glyphs)..high(glyphs)]) then begin
      if a < length(text) then
        inc(MeasureBMFont, glyphs[glyphIdx].xadvance + font.spacing[0])
      else
        inc(MeasureBMFont, glyphs[glyphIdx].xadvance);
    end;
  end;
end;

{ Returns xadvance for the next char }
function PrintBMFontCharColour(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyphLegacy;
  const ch: char;
  const x, y: smallint;
  const colour: longword): word;
var
  charcode: byte;
  glyphIdx: smallint;
  glyph: TBMFontGlyphLegacy;
begin
  charcode := ord(ch);
  glyphIdx := charcode;

  PrintBMFontCharColour := 0;

  if (glyphIdx in [low(fontGlyphs)..high(fontGlyphs)]) then begin
    glyph := fontGlyphs[glyphIdx];

    SprRegionSolid(
      font.texHandle,
      glyph.x, glyph.y,
      glyph.width, glyph.height,
      x + glyph.xoffset, y + glyph.yoffset,
      colour);

    PrintBMFontCharColour := glyph.xadvance
  end;
end;

procedure PrintBMFontColour(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyphLegacy;
  const text: string;
  const x, y: smallint;
  const colour: longword);
var
  a: word;
  left, step: smallint;
begin
  left := 0;

  for a:=1 to length(text) do begin
    step := PrintBMFontCharColour(
        font, fontGlyphs,
        text[a],
        x + left, y,
        colour);

    if a < length(text) then
      inc(left, step + font.spacing[0])
    else
      inc(left, step);
  end;
end;


function PrintBMFontCharToDest(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyphLegacy;
  const destHandle: longint;
  const ch: char;
  const x, y: smallint): smallint;
var
  charcode: byte;
  glyphIdx: smallint;
  glyph: TBMFontGlyphLegacy;
begin
  PrintBMFontCharToDest := 0;

  if not IsTextureSet(destHandle) then exit;

  charcode := ord(ch);

  glyphIdx := charcode;

  if (glyphIdx in [low(fontGlyphs)..high(fontGlyphs)]) then begin
    glyph := fontGlyphs[glyphIdx];

    SprRegionToDest(
      font.texHandle,
      destHandle,
      glyph.x, glyph.y,
      glyph.width, glyph.height,
      x + glyph.xoffset, y + glyph.yoffset);
    
    PrintBMFontCharToDest := glyph.xadvance
  end else
    PrintBMFontCharToDest := 0;
end;

procedure PrintBMFontToDest(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyphLegacy;
  const destHandle: longint;
  const text: string;
  const x, y: smallint);
var
  a: word;
  ch: char;
  left, step: smallint;
begin
  left := 0;

  for a:=1 to length(text) do begin
    ch := text[a];
    step := PrintBMFontCharToDest(font, fontGlyphs, destHandle, ch, x + left, y);

    if a < length(text) then
      inc(left, step + font.spacing[0])
    else
      inc(left, step);
  end;
end;

end.
