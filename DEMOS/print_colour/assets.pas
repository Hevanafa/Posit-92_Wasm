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

procedure printColour(
  const text: string;
  const x, y: integer;
  const font: TBMFont;
  const fontGlyphs: array of TBMFontGlyph;
  const colour: longword);
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

      { TODO: Expand this }
      sprRegion(
        font.imgHandle,
        glyph.x, glyph.y,
        glyph.width, glyph.height,
        x + left + glyph.xoffset, y + glyph.yoffset);

      inc(left, glyph.xadvance)
    end;
  end;
end;


{ Asset boilerplate }
procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
procedure setImgDosuEXE(const imgHandle: longint; const idx: integer); public name 'setImgDosuEXE';


implementation

uses Conv;

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