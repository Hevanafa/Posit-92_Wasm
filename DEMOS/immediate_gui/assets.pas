unit Assets;

{$Mode TP}

interface

uses BMFont;

var
  { for use in loadBMFont }
  defaultFont: TBMFont;
  defaultFontGlyphs: array[32..126] of TBMFontGlyph;
  picotronFont: TBMFont;
  picotronFontGlyphs: array[32..126] of TBMFontGlyph;

  imgCursor: longint;
  imgDosuEXE: array[0..1] of longint;

{ BMFont boilerplate }
function defaultFontPtr: PBMFont; public name 'defaultFontPtr';
function defaultFontGlyphsPtr: pointer; public name 'defaultFontGlyphsPtr';

function picotronFontPtr: PBMFont; public name 'picotronFontPtr';
function picotronFontGlyphsPtr: pointer; public name 'picotronFontGlyphsPtr';

procedure printDefault(const text: string; const x, y: integer);
function measureDefault(const text: string): word;

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

function defaultFontGlyphsPtr: pointer;
begin
  defaultFontGlyphsPtr := @defaultFontGlyphs
end;

function picotronFontPtr: PBMFont;
begin
  picotronFontPtr := @picotronFont
end;

function picotronFontGlyphsPtr: pointer;
begin
  picotronFontGlyphsPtr := @picotronFontGlyphs
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