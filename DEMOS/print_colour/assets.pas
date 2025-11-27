unit Assets;

{$Mode TP}

interface

uses BMFont;

var
  { for use in loadBMFont }
  defaultFont: TBMFont;
  defaultFontGlyphs: array[32..126] of TBMFontGlyph;

  imgCursor: longint;
  imgDosuEXE: array[0..1] of longint;

{ BMFont boilerplate }
function defaultFontPtr: PBMFont; public name 'defaultFontPtr';
function defaultFontGlyphsPtr: PBMFontGlyph; public name 'defaultFontGlyphsPtr';

procedure printDefault(const text: string; const x, y: integer);
function measureDefault(const text: string): word;

procedure sprRegionSolid(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const colour: longword);

procedure printColour(
  const text: string;
  const x, y: integer;
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const colour: longword);


{ Asset boilerplate }
procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
procedure setImgDosuEXE(const imgHandle: longint; const idx: integer); public name 'setImgDosuEXE';


implementation

uses Bitmap, Conv, VGA;

{ Begin BMFont boilerplate}

function defaultFontPtr: PBMFont;
begin
  defaultFontPtr := @defaultFont
end;

function defaultFontGlyphsPtr: PBMFontGlyph;
begin
  defaultFontGlyphsPtr := @defaultFontGlyphs
end;

procedure printDefault(const text: string; const x, y: integer);
begin
  printBMFont(text, x, y, defaultFont, defaultFontGlyphs)
end;

function measureDefault(const text: string): word;
begin
  measureDefault := measureBMFont(text, defaultFontGlyphs)
end;

procedure sprRegionSolid(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const colour: longword);
var
  image: PBitmap;
  a, b: integer;
  sx, sy: integer;
  srcPos: longint;
  alpha: byte;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for b:=0 to srcH - 1 do
  for a:=0 to srcW - 1 do begin
    if (destX + a >= vgaWidth) or (destX + a < 0)
      or (destY + b >= vgaHeight) or (destY + b < 0) then continue;

    sx := srcX + a;
    sy := srcY + b;
    srcPos := (sx + sy * image^.width) * 4;

    alpha := image^.data[srcPos + 3];
    if alpha < 255 then continue;

    { colour := unsafeSprPget(image, sx, sy); }
    unsafePset(destX + a, destY + b, colour);
  end;
end;

{ Returns xadvance for the next char }
function printCharColour(
  const ch: char;
  const x, y: integer;
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
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

  printCharColour := result
end;

procedure printColour(
  const text: string;
  const x, y: integer;
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const colour: longword);
var
  a: word;
  left: integer;
begin
  left := 0;

  for a:=1 to length(text) do
    inc(left, printCharColour(text[a], x + left, y, font, fontGlyphs, colour))
end;


{ Begin asset boilerplate }

procedure setImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure setImgDosuEXE(const imgHandle: longint; const idx: integer);
begin
  imgDosuEXE[idx] := imgHandle
end;

end.