unit Assets;

{$Mode TP}

interface

uses P92BMFont;

var
  { for use in loadBMFont }
  blackFont: TBMFont;
  blackFontGlyphs: array[32..126] of TBMFontGlyph;

  picotronFont: TBMFont;
  picotronFontGlyphs: array[32..126] of TBMFontGlyph;

  imgCursor, imgHandCursor: longint;
  imgDosuEXE: array[0..1] of longint;
  imgWinNormal, imgWinHovered, imgWinPressed: longint;


implementation

end.
