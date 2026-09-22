unit Assets;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses BMFont;

var
  { for use in loadBMFont }
  defaultFont: TBMFont;
  defaultFontGlyphs: array[32..126] of TBMFontGlyph;

  imgCursor: longint;
  imgTicsy: longint;

{ BMFont boilerplate }
function defaultFontPtr: PBMFont; public name 'defaultFontPtr';
function defaultFontGlyphsPtr: PBMFontGlyph; public name 'defaultFontGlyphsPtr';

procedure printDefault(const text: string; const x, y: integer);
procedure printDefaultCentred(const text: string; const cx, y: integer);
function measureDefault(const text: string): word;

{ Asset boilerplate }
procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
procedure setImgTicsy(const imgHandle: longint); public name 'setImgTicsy';


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
  printBMFont(defaultFont, defaultFontGlyphs, text, x, y)
end;

procedure printDefaultCentred(const text: string; const cx, y: integer);
var
  w: word;
begin
  w := measureDefault(text);
  printDefault(text, cx - w div 2, y)
end;

function measureDefault(const text: string): word;
begin
  measureDefault := measureBMFont(defaultFont, defaultFontGlyphs, text)
end;


{ Begin asset boilerplate }

procedure setImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure setImgTicsy(const imgHandle: longint);
begin
  imgTicsy := imgHandle
end;

end.
