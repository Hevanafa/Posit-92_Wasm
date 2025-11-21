unit Assets;

{$Mode ObjFPC}

interface

uses BMFont;

var
  { for use in loadBMFont }
  _defaultFont: TBMFont;
  _defaultFontGlyphs: array[32..126] of TBMFontGlyph;

  imgCursor: longint;
  imgDosuEXE: array[0..1] of longint;

{ BMFont boilerplate }
function defaultFontPtr: pointer; public name 'defaultFontPtr';
function defaultFontGlyphsPtr: pointer; public name 'defaultFontGlyphsPtr';
procedure printDefault(const text: string; const x, y: integer);
{ for use with JS }
procedure printDefault(const textPtr: pointer; const textLen: integer; const x, y: integer); public name 'printDefault';

{ Asset boilerplate }
procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
procedure setImgDosuEXE(const imgHandle: longint; const idx: integer); public name 'setImgDosuEXE';


implementation

uses Conv;

{ Begin BMFont boilerplate}

function defaultFontPtr: pointer;
begin
  defaultFontPtr := @_defaultFont
end;

function defaultFontGlyphsPtr: pointer;
begin
  defaultFontGlyphsPtr := @_defaultFontGlyphs
end;

procedure printDefault(const text: string; const x, y: integer);
begin
  printBMFont(text, x, y, _defaultFont, _defaultFontGlyphs)
end;

{ for use with JS }
procedure printDefault(const textPtr: pointer; const textLen: integer; const x, y: integer);
var
  text: string;
begin
  text := strPtrToString(textPtr, textLen);
  printBMFont(text, x, y, _defaultFont, _defaultFontGlyphs)
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