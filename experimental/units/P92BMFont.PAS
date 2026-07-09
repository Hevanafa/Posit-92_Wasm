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
  PBMFontGlyph = ^TBMFontGlyph;
  TBMFontGlyph = record
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

  PBMFont = ^TBMFont;
  TBMFont = record
    texHandle: longint;
    lineHeight: smallint;
    spacing: array[0..1] of byte;
    glyphs: array[0..255] of TBMFontGlyph;
  end;

  { Used in asset registry }
  TBMFontHandle = type longint;


{ This procedure creates a new ImgRef instance }
procedure CloneBMFontLegacy(
  const srcFont: TBMFontLegacy; const srcFontGlyphs: array of TBMFontGlyph;
  var destFont: TBMFontLegacy; var destFontGlyphs: array of TBMFontGlyph);

procedure FreeBMFontLegacy(
  var font: TBMFontLegacy;
  var fontGlyphs: array of TBMFontGlyph;
  const freeImgHandle: boolean);

procedure PrintBMFont(
  const fontHandle: TBMFontHandle;
  const text: string;
  const x, y: smallint);

function MeasureBMFont(
  const fontHandle: TBMFontHandle;
  const text: string): smallint;

function PrintBMFontCharColour(
  const fontHandle: TBMFontHandle;
  const ch: char;
  const x, y: smallint;
  const colour: longword): word;

procedure PrintBMFontColour(
  const fontHandle: TBMFontHandle;
  const text: string;
  const x, y: smallint;
  const colour: longword);

function PrintBMFontCharToDest(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyph;
  const destHandle: longint;
  const ch: char;
  const x, y: smallint): smallint;

procedure PrintBMFontToDest(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyph;
  const destHandle: longint;
  const text: string;
  const x, y: smallint);


implementation

uses
  P92Conversions, P92Logger, P92AssetRegistry,
  P92Tex, P92TexDraw;

{ Returns glyph.xadvance }
function PrintBMFontChar(
  const fontHandle: TBMFontHandle;
  const ch: char;
  const x, y: smallint): smallint;
var
  fontPtr: PBMFont;
  charcode: byte;
  glyphIdx: smallint;
  glyph: TBMFontGlyph;
begin
  fontPtr := @bmfonts[fontHandle].font;

  charcode := ord(ch);
  glyphIdx := charcode;

  if (glyphIdx in [low(fontPtr^.glyphs)..high(fontPtr^.glyphs)]) then begin
    glyph := fontPtr^.glyphs[glyphIdx];

    SprRegion(
      fontPtr^.texHandle,
      glyph.x, glyph.y,
      glyph.width, glyph.height,
      x + glyph.xoffset, y + glyph.yoffset);
    
    PrintBMFontChar := glyph.xadvance
  end else
    PrintBMFontChar := 0;
end;

procedure CloneBMFontLegacy(
  const srcFont: TBMFontLegacy; const srcFontGlyphs: array of TBMFontGlyph;
  var destFont: TBMFontLegacy; var destFontGlyphs: array of TBMFontGlyph);
var
  a: word;
begin
  destFont := srcFont;

  for a:=0 to high(srcFontGlyphs) do
    destFontGlyphs[a] := srcFontGlyphs[a];

  destFont.texHandle := CopyTexture(srcFont.texHandle)
end;

procedure FreeBMFontLegacy(
  var font: TBMFontLegacy;
  var fontGlyphs: array of TBMFontGlyph;
  const freeImgHandle: boolean);
var
  a: Word;
begin
  if freeImgHandle then
    FreeTexture(font.texHandle);

  fillchar(font, sizeof(TBMFontLegacy), 0);
  for a:=0 to high(fontGlyphs) do
    fillchar(fontGlyphs[a], sizeof(TBMFontGlyph), 0);
end;

procedure PrintBMFont(
  const fontHandle: TBMFontHandle;
  const text: string;
  const x, y: smallint);
var
  fontPtr: PBMFont;
  a: word;
  ch: char;
  left, step: smallint;
begin
  left := 0;

  for a:=1 to length(text) do begin
    ch := text[a];
    step := PrintBMFontChar(fontHandle, ch, x + left, y);

    if a < length(text) then
      inc(left, step + fontPtr^.spacing[0])
    else
      inc(left, step);
  end;
end;


function MeasureBMFont(
  const fontHandle: TBMFontHandle;
  const text: string): smallint;
var
  fontPtr: PBMFont;
  a: word;
  glyphIdx: smallint;
  charcode: byte;
begin
  MeasureBMFont := 0;

  fontPtr := @bmfonts[fontHandle].font;

  for a:=1 to length(text) do begin
    charcode := ord(text[a]);

    glyphIdx := charcode;

    if (glyphIdx in [low(fontPtr^.glyphs)..high(fontPtr^.glyphs)]) then begin
      if a < length(text) then
        inc(MeasureBMFont, fontPtr^.glyphs[glyphIdx].xadvance + fontPtr^.spacing[0])
      else
        inc(MeasureBMFont, fontPtr^.glyphs[glyphIdx].xadvance);
    end;
  end;
end;

{ Returns xadvance for the next char }
function PrintBMFontCharColour(
  const fontHandle: TBMFontHandle;
  const ch: char;
  const x, y: smallint;
  const colour: longword): word;
var
  fontPtr: PBMFont;
  charcode: byte;
  glyphIdx: smallint;
  glyph: TBMFontGlyph;
begin
  fontPtr := @bmfonts[fontHandle].font;
  charcode := ord(ch);
  glyphIdx := charcode;

  PrintBMFontCharColour := 0;

  if (glyphIdx in [low(fontPtr^.glyphs)..high(fontPtr^.glyphs)]) then begin
    glyph := fontPtr^.glyphs[glyphIdx];

    SprRegionSolid(
      fontPtr^.texHandle,
      glyph.x, glyph.y,
      glyph.width, glyph.height,
      x + glyph.xoffset, y + glyph.yoffset,
      colour);

    PrintBMFontCharColour := glyph.xadvance
  end;
end;

procedure PrintBMFontColour(
  const fontHandle: TBMFontHandle;
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
        fontHandle,
        text[a],
        x + left, y,
        colour);

    if a < length(text) then
      inc(left, step + bmfonts[fontHandle].font.spacing[0])
    else
      inc(left, step);
  end;
end;


function PrintBMFontCharToDest(
  const font: TBMFontLegacy;
  const fontGlyphs: array of TBMFontGlyph;
  const destHandle: longint;
  const ch: char;
  const x, y: smallint): smallint;
var
  charcode: byte;
  glyphIdx: smallint;
  glyph: TBMFontGlyph;
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
  const fontGlyphs: array of TBMFontGlyph;
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
