unit Assets;

{$Mode TP}

interface

uses BMFont;

var
  { for use in loadBMFont }
  blackFont: TBMFont;
  blackFontGlyphs: array[32..126] of TBMFontGlyph;

  picotronFont: TBMFont;
  picotronFontGlyphs: array[32..126] of TBMFontGlyph;

  imgCursor, imgHandCursor: longint;
  imgDosuEXE: array[0..1] of longint;
  imgWinNormal, imgWinHovered, imgWinPressed: longint;

{ BMFont boilerplate }
function BlackFontPtr: PBMFont; public name 'BlackFontPtr';
function BlackFontGlyphsPtr: PBMFontGlyph; public name 'BlackFontGlyphsPtr';

function PicotronFontPtr: PBMFont; public name 'PicotronFontPtr';
function PicotronFontGlyphsPtr: PBMFontGlyph; public name 'PicotronFontGlyphsPtr';

{ Asset boilerplate }
procedure SetImgCursor(const imgHandle: longint); public name 'SetImgCursor';
procedure SetImgHandCursor(const imgHandle: longint); public name 'SetImgHandCursor';
procedure SetImgDosu(const imgHandle: longint; const idx: integer); public name 'SetImgDosu';

procedure SetImgWinNormal(const imgHandle: longint); public name 'SetImgWinNormal';
procedure SetImgWinHovered(const imgHandle: longint); public name 'SetImgWinHovered';
procedure SetImgWinPressed(const imgHandle: longint); public name 'SetImgWinPressed';


implementation

uses Conv;

{ Begin BMFont boilerplate}

function BlackFontPtr: PBMFont;
begin
  BlackFontPtr := @blackFont
end;

function BlackFontGlyphsPtr: PBMFontGlyph;
begin
  BlackFontGlyphsPtr := @blackFontGlyphs
end;

function PicotronFontPtr: PBMFont;
begin
  PicotronFontPtr := @picotronFont
end;

function PicotronFontGlyphsPtr: PBMFontGlyph;
begin
  PicotronFontGlyphsPtr := @picotronFontGlyphs
end;


{ Begin asset boilerplate }

procedure SetImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure SetImgHandCursor(const imgHandle: longint);
begin
  imgHandCursor := imgHandle
end;

procedure SetImgDosu(const imgHandle: longint; const idx: integer);
begin
  imgDosuEXE[idx] := imgHandle
end;

procedure SetImgWinNormal(const imgHandle: longint);
begin
  imgWinNormal := imgHandle
end;

procedure SetImgWinHovered(const imgHandle: longint);
begin
  imgWinHovered := imgHandle
end;

procedure SetImgWinPressed(const imgHandle: longint);
begin
  imgWinPressed := imgHandle
end;


end.
