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
  imgDosuExe: array[0..1] of longint;

{ BMFont boilerplate }
function DefaultFontPtr: PBMFont; public name 'DefaultFontPtr';
function DefaultFontGlyphsPtr: PBMFontGlyph; public name 'DefaultFontGlyphsPtr';

procedure PrintDefault(const text: string; const x, y: integer);
procedure PrintDefaultCentred(const text: string; const cx, y: integer);
function MeasureDefault(const text: string): word;

{ Asset boilerplate }
procedure SetImgCursor(const imgHandle: longint); public name 'SetImgCursor';
procedure SetImgDosuExe(const imgHandle: longint; const idx: integer); public name 'SetImgDosuExe';


implementation

uses Conv;

{ Begin BMFont boilerplate}

function DefaultFontPtr: PBMFont;
begin
  DefaultFontPtr := @defaultFont
end;

function DefaultFontGlyphsPtr: PBMFontGlyph;
begin
  DefaultFontGlyphsPtr := @defaultFontGlyphs
end;

procedure PrintDefault(const text: string; const x, y: integer);
begin
  printBMFont(defaultFont, defaultFontGlyphs, text, x, y)
end;

procedure PrintDefaultCentred(const text: string; const cx, y: integer);
var
  w: word;
begin
  w := MeasureDefault(text);
  PrintDefault(text, cx - w div 2, y)
end;

function MeasureDefault(const text: string): word;
begin
  MeasureDefault := measureBMFont(defaultFont, defaultFontGlyphs, text)
end;


{ Begin asset boilerplate }

procedure SetImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure SetImgDosuExe(const imgHandle: longint; const idx: integer);
begin
  imgDosuExe[idx] := imgHandle
end;

end.
