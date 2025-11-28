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

  imgCursorRef: longint;
  imgGasolineMaid: longint;

{ BMFont boilerplate }
function defaultFontPtr: PBMFont; public name 'defaultFontPtr';
function defaultFontGlyphsPtr: PBMFontGlyph; public name 'defaultFontGlyphsPtr';

procedure printDefault(const text: string; const x, y: integer);
function measureDefault(const text: string): word;

{ Asset boilerplate }
{ procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor'; }
procedure setImgDosuEXE(const imgHandle: longint; const idx: integer); public name 'setImgDosuEXE';

{ Use TImageRef instead of TBitmap }
procedure setImgCursorRef(const imgHandle: longint); public name 'setImgCursorRef';
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
  printBMFont(text, x, y, defaultFont, defaultFontGlyphs)
end;

function measureDefault(const text: string): word;
begin
  measureDefault := measureBMFont(text, defaultFontGlyphs)
end;


{ Begin asset boilerplate }

{ procedure setImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end; }

procedure setImgDosuEXE(const imgHandle: longint; const idx: integer);
begin
  imgDosuEXE[idx] := imgHandle
end;

procedure setImgCursorRef(const imgHandle: longint);
begin
  imgCursorRef := imgHandle
end;

procedure setImgGasolineMaid(const imgHandle: longint);
begin
  imgGasolineMaid := imgHandle
end;


end.