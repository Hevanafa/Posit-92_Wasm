unit Assets;

{$Mode TP}

interface

uses BMFont;

var
  { for use in loadBMFont }
  defaultFont: TBMFont;
  defaultFontGlyphs: array[32..126] of TBMFontGlyph;

  imgCursor, imgHandCursor: longint;
  imgDosuEXE: array[0..1] of longint;
  imgSlimeGirl: longint;
  { https://kenney.nl/assets/desert-shooter-pack }
  imgBlueEnemy: longint;

{ BMFont boilerplate }
function defaultFontPtr: pointer; public name 'defaultFontPtr';
function defaultFontGlyphsPtr: pointer; public name 'defaultFontGlyphsPtr';
procedure printDefault(const text: string; const x, y: integer);
function measureDefault(const text: string): word;

{ Asset boilerplate }
procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
procedure setImgHandCursor(const imgHandle: longint); public name 'setImgHandCursor';
procedure setImgDosuEXE(const imgHandle: longint; const idx: integer); public name 'setImgDosuEXE';
procedure setImgSlimeGirl(const imgHandle: longint); public name 'setImgSlimeGirl';
procedure setImgBlueEnemy(const imgHandle: longint); public name 'setImgBlueEnemy';


implementation

uses Conv;

{ Begin BMFont boilerplate}

function defaultFontPtr: pointer;
begin
  defaultFontPtr := @defaultFont
end;

function defaultFontGlyphsPtr: pointer;
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

procedure setImgHandCursor(const imgHandle: longint);
begin
  imgHandCursor := imgHandle
end;

procedure setImgDosuEXE(const imgHandle: longint; const idx: integer);
begin
  imgDosuEXE[idx] := imgHandle
end;

procedure setImgSlimeGirl(const imgHandle: longint);
begin
  imgSlimeGirl := imgHandle
end;

procedure setImgBlueEnemy(const imgHandle: longint);
begin
  imgBlueEnemy := imgHandle
end;

end.