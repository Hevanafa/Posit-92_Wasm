unit Assets;

{$Mode ObjFPC}

interface

uses BMFont;

var
  { for use in loadBMFont }
  defaultFont, boldFont: TBMFont;
  defaultFontGlyphs, boldFontGlyphs: array[32..126] of TBMFontGlyph;

  imgCursor: longint;
  imgDosuEXE: array[0..1] of longint;

{ BMFont boilerplate }
function defaultFontPtr: PBMFont; public name 'defaultFontPtr';
function defaultFontGlyphsPtr: PBMFontGlyph; public name 'defaultFontGlyphsPtr';
function boldFontPtr: PBMFont; public name 'boldFontPtr';
function boldFontGlyphsPtr: PBMFontGlyph; public name 'boldFontGlyphsPtr';

procedure printDefault(const text: string; const x, y: integer);
procedure printDefaultCentred(const text: string; const cx, y: integer);
function measureDefault(const text: string): word;

{ Asset boilerplate }
procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
procedure setImgDosuEXE(const imgHandle: longint; const idx: integer); public name 'setImgDosuEXE';


implementation

uses Conv;

{ Begin BMFont boilerplate}

function defaultFontPtr: PBMFont;
begin defaultFontPtr := @defaultFont end;

function defaultFontGlyphsPtr: PBMFontGlyph;
begin defaultFontGlyphsPtr := @defaultFontGlyphs end;

function boldFontPtr: PBMFont;
begin boldFontPtr := @boldFont end;

function boldFontGlyphsPtr: PBMFontGlyph;
begin boldFontGlyphsPtr := @boldFontGlyphs end;

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
  measureDefault := measureBMFont(defaultFontGlyphs, text)
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