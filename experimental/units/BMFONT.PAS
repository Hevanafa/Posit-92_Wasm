{
  BMFont - Part of Posit-92 game engine
  Hevanafa
}

unit BMFont;

{$Mode ObjFPC}
{$H-}
{$J-}

interface

type
  PBMFontGlyph = ^TBMFontGlyph;
  TBMFontGlyph = record
    id: word;
    x, y, width, height: word;
    xoffset, yoffset: smallint;
    xadvance: smallint;
  end;

  PBMFont = ^TBMFont;
  TBMFont = record
    face: string[15];  { 16 bytes }
    filename: string[63];  { 64 bytes }
    lineHeight: word;  { 2 bytes }
    spacing: array[0..1] of byte; { x, y }
    imgHandle: longint;  { 84th byte }
  end;

{ This procedure creates a new ImgRef instance }
procedure cloneBMFont(
  const srcFont: TBMFont; const srcFontGlyphs: array of TBMFontGlyph;
  var destFont: TBMFont; var destFontGlyphs: array of TBMFontGlyph);

procedure freeBMFont(
  var font: TBMFont;
  var fontGlyphs: array of TBMFontGlyph;
  const freeImgHandle: boolean);

procedure printBMFont(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const text: string;
  const x, y: smallint);

function measureBMFont(
  const font: TBMFont;
  const glyphs: array of TBMFontGlyph;
  const text: string): smallint;

function printBMFontCharColour(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const ch: char;
  const x, y: smallint;
  const colour: longword): word;

procedure printBMFontColour(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const text: string;
  const x, y: smallint;
  const colour: longword);

function printBMFontCharToDest(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const destHandle: longint;
  const ch: char;
  const x, y: smallint): smallint;

procedure printBMFontToDest(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const destHandle: longint;
  const text: string;
  const x, y: smallint);


implementation

uses
  Conv, Logger,
  ImgRef, ImgRefFast;

{ Returns glyph.xadvance }
function printBMFontChar(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const ch: char;
  const x, y: smallint): smallint;
var
  charcode: byte;
  glyphIdx: smallint;
  glyph: TBMFontGlyph;
begin
  charcode := ord(ch);

  { Assuming the starting charcode is always 32 }
  glyphIdx := charcode - 32;

  if (glyphIdx in [low(fontGlyphs)..high(fontGlyphs)]) then begin
    glyph := fontGlyphs[glyphIdx];

    sprRegion(
      font.imgHandle,
      glyph.x, glyph.y,
      glyph.width, glyph.height,
      x + glyph.xoffset, y + glyph.yoffset);
    
    printBMFontChar := glyph.xadvance
  end else
    printBMFontChar := 0;
end;

procedure cloneBMFont(
  const srcFont: TBMFont; const srcFontGlyphs: array of TBMFontGlyph;
  var destFont: TBMFont; var destFontGlyphs: array of TBMFontGlyph);
var
  a: word;
begin
  destFont := srcFont;

  for a:=0 to high(srcFontGlyphs) do
    destFontGlyphs[a] := srcFontGlyphs[a];

  destFont.imgHandle := copyImage(srcFont.imgHandle)
end;

procedure freeBMFont(
  var font: TBMFont;
  var fontGlyphs: array of TBMFontGlyph;
  const freeImgHandle: boolean);
var
  a: Word;
begin
  if freeImgHandle then
    freeImage(font.imgHandle);

  fillchar(font, sizeof(TBMFont), 0);
  for a:=0 to high(fontGlyphs) do
    fillchar(fontGlyphs[a], sizeof(TBMFontGlyph), 0);
end;

procedure printBMFont(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
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
    step := printBMFontChar(font, fontGlyphs, ch, x + left, y);

    if a < length(text) then
      inc(left, step + font.spacing[0])
    else
      inc(left, step);
  end;
end;


function measureBMFont(
  const font: TBMFont;
  const glyphs: array of TBMFontGlyph;
  const text: string): smallint;
var
  a: word;
  glyphIdx: smallint;
  charcode: byte;
begin
  result := 0;

  for a:=1 to length(text) do begin
    charcode := ord(text[a]);

    { Assuming the starting charcode is always 32 }
    glyphIdx := charcode - 32;

    if (glyphIdx in [low(glyphs)..high(glyphs)]) then begin
      if a < length(text) then
        inc(result, glyphs[glyphIdx].xadvance + font.spacing[0])
      else
        inc(result, glyphs[glyphIdx].xadvance);
    end;
  end;

  measureBMFont := result
end;

{ Returns xadvance for the next char }
function printBMFontCharColour(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const ch: char;
  const x, y: smallint;
  const colour: longword): word;
var
  charcode: byte;
  glyphIdx: smallint;
  glyph: TBMFontGlyph;
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
  const x, y: smallint;
  const colour: longword);
var
  a: word;
  left, step: smallint;
begin
  left := 0;

  for a:=1 to length(text) do begin
    step := printBMFontCharColour(
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


function printBMFontCharToDest(
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const destHandle: longint;
  const ch: char;
  const x, y: smallint): smallint;
var
  charcode: byte;
  glyphIdx: smallint;
  glyph: TBMFontGlyph;
begin
  printBMFontCharToDest := 0;

  if not isImageSet(destHandle) then exit;

  charcode := ord(ch);

  { Assuming the starting charcode is always 32 }
  glyphIdx := charcode - 32;

  if (glyphIdx in [low(fontGlyphs)..high(fontGlyphs)]) then begin
    glyph := fontGlyphs[glyphIdx];

    sprRegionToDest(
      font.imgHandle,
      destHandle,
      glyph.x, glyph.y,
      glyph.width, glyph.height,
      x + glyph.xoffset, y + glyph.yoffset);
    
    printBMFontCharToDest := glyph.xadvance
  end else
    printBMFontCharToDest := 0;
end;

procedure printBMFontToDest(
  const font: TBMFont;
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
    step := printBMFontCharToDest(font, fontGlyphs, destHandle, ch, x + left, y);

    if a < length(text) then
      inc(left, step + font.spacing[0])
    else
      inc(left, step);
  end;
end;

end.
