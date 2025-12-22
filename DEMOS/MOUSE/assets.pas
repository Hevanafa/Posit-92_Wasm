unit Assets;

{$Mode ObjFPC}

interface

uses BMFont;

var
  { for use in loadBMFont }
  defaultFont: TBMFont;
  defaultFontGlyphs: array[32..126] of TBMFontGlyph;

  imgCursor, imgGasolineMaid: longint;

{ BMFont boilerplate }
function defaultFontPtr: PBMFont; public name 'defaultFontPtr';
function defaultFontGlyphsPtr: PBMFontGlyph; public name 'defaultFontGlyphsPtr';

procedure printDefault(const text: string; const x, y: integer);

{ Asset boilerplate }
procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
procedure setImgGasolineMaid(const imgHandle: longint); public name 'setImgGasolineMaid';


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


{ Begin asset boilerplate }

procedure setImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure setImgGasolineMaid(const imgHandle: longint);
begin
  imgGasolineMaid := imgHandle
end;

end.