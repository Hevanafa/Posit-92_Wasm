unit Assets;

{$Mode TP}

interface

uses BMFont;

var
  { for use in loadBMFont }
  defaultFont: TBMFont;
  defaultFontGlyphs: array[32..126] of TBMFontGlyph;
  blackFont: TBMFont;
  blackFontGlyphs: array[32..126] of TBMFontGlyph;

  picotronFont: TBMFont;
  picotronFontGlyphs: array[32..126] of TBMFontGlyph;

  imgCursor, imgHandCursor: longint;
  imgDosuEXE: array[0..1] of longint;

{ BMFont boilerplate }
function defaultFontPtr: PBMFont; public name 'defaultFontPtr';
function defaultFontGlyphsPtr: pointer; public name 'defaultFontGlyphsPtr';
function blackFontPtr: PBMFont; public name 'blackFontPtr';
function blackFontGlyphsPtr: pointer; public name 'blackFontGlyphsPtr';

function picotronFontPtr: PBMFont; public name 'picotronFontPtr';
function picotronFontGlyphsPtr: pointer; public name 'picotronFontGlyphsPtr';

procedure printDefault(const text: string; const x, y: integer);
function measureDefault(const text: string): word;

{ Asset boilerplate }
procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
procedure setImgHandCursor(const imgHandle: longint); public name 'setImgHandCursor';
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

function blackFontPtr: PBMFont;
begin
  blackFontPtr := @blackFont
end;

function blackFontGlyphsPtr: pointer;
begin
  blackFontGlyphsPtr := @blackFontGlyphs
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

procedure setImgHandCursor(const imgHandle: longint);
begin
  imgHandCursor := imgHandle
end;

procedure setImgDosuEXE(const imgHandle: longint; const idx: integer);
begin
  imgDosuEXE[idx] := imgHandle
end;

end.