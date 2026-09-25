unit Assets;

{$Mode TP}

interface

uses
  P92AssetHandles, P92BMFont;

var
  fontRegular, fontBlack, fontBold: TBMFontHandle;

  texCursor, texHandCursor: TTextureHandle;
  texDosuEXE: array[0..1] of TTextureHandle;
  texWinNormal, texWinHovered, texWinPressed: TTextureHandle;
  texPromptBG, texPromptButtonNormal, texPromptButtonPressed: TTextureHandle;
  tex9SliceNormal, tex9SliceHovered, tex9SlicePressed: TTextureHandle;


implementation

end.
