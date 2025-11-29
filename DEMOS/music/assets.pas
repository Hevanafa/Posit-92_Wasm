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

  imgPlay: longint;
  imgStop: longint;
  imgPause: longint;
  imgVolumeOn, imgVolumeOff: longint;

{ BMFont boilerplate }
function defaultFontPtr: PBMFont; public name 'defaultFontPtr';
function defaultFontGlyphsPtr: PBMFontGlyph; public name 'defaultFontGlyphsPtr';

procedure printDefault(const text: string; const x, y: integer);
function measureDefault(const text: string): word;

{ Asset boilerplate }
procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
procedure setImgDosuEXE(const imgHandle: longint; const idx: integer); public name 'setImgDosuEXE';

procedure setImgPlay(const imgHandle: longint); public name 'setImgPlay';
procedure setImgStop(const imgHandle: longint); public name 'setImgStop';
procedure setImgPause(const imgHandle: longint); public name 'setImgPause';
procedure setImgVolumeOn(const imgHandle: longint); public name 'setImgVolumeOn';
procedure setImgVolumeOff(const imgHandle: longint); public name 'setImgVolumeOff';


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

procedure setImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure setImgDosuEXE(const imgHandle: longint; const idx: integer);
begin
  imgDosuEXE[idx] := imgHandle
end;

procedure setImgPlay(const imgHandle: longint);
begin
  imgPlay := imgHandle
end;

procedure setImgStop(const imgHandle: longint);
begin
  imgStop := imgHandle
end;

procedure setImgPause(const imgHandle: longint);
begin
  imgPause := imgHandle
end;

procedure setImgVolumeOn(const imgHandle: longint);
begin
  imgVolumeOn := imgHandle
end;

procedure setImgVolumeOff(const imgHandle: longint);
begin
  imgVolumeOff := imgHandle
end;


end.