{
  Immediate GUI Implementation
  Part of Posit-92 game engine
  By Hevanafa, 22-11-2025

  Based on my QB64 Immediate GUI implementation
}

library Game;

{$Mode ObjFPC}

uses
  P92Core, P92BMFont, P92Fonts, P92Conversions, P92FPS, P92Graphics,
  P92AssetRegistry,
  P92WasmHost, P92Tex, P92TexDraw, P92TexEffects, P92Keyboard, P92Mouse, P92AssetHandles,
  P92Geometry, P92Timing, P92VGA, P92IMGUI, P92IMGUIPromptBox, P92Panic,
  Assets;

type
  TNineSliceMargins = record
    top, right, bottom, left: integer
  end;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  CornflowerBlue = $FF6495ED;
  SemitransparentBlack = $80000000;

  demoMargins: TNineSliceMargins = (top: 8; right: 8; bottom: 8; left: 8);

  { Prompts enum }
  PromptTest = 1;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  clicks: word;
  showFPS: TCheckboxState;

procedure DrawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  if hasHoveredWidget then
    spr(texHandCursor, GetMouseX - 5, GetMouseY - 1)
  else
    spr(texCursor, GetMouseX, GetMouseY);
end;


procedure SprNineSlice(
  const texHandle: TTextureHandle;
  const x, y, width, height: integer;
  const margins: TNineSliceMargins);
var
  srcCentreW, srcCentreH: integer;
  destCentreW, destCentreH: integer;
begin
  if not IsTexSet(texHandle) then
    panicHalt('sprNineSlice: imgHandle is ' + i32str(texHandle) + '!');

  srcCentreW := GetTexWidth(texHandle) - margins.left - margins.right;
  srcCentreH := GetTexHeight(texHandle) - margins.top - margins.bottom;
  destCentreW := width - margins.left - margins.right;
  destCentreH := height - margins.top - margins.bottom;

  { Middle fill }
  sprRegionStretch(texHandle,
    margins.left, margins.top, srcCentreW, srcCentreH,
    x + margins.left, y + margins.top, destCentreW, destCentreH);
  
  { Top side }
  sprRegionStretch(
    texHandle,
    margins.left, 0, srcCentreW, margins.top,
    x + margins.left, y, destCentreW, margins.top);
  
  { Bottom side }
  SprRegionStretch(
    texHandle,

    margins.left,
    GetTexHeight(texHandle) - margins.bottom,
    srcCentreW,
    margins.bottom,

    x + margins.left,
    y + height - margins.bottom,
    destCentreW,
    margins.bottom);

  { Left side }
  sprRegionStretch(
    texHandle,

    0, margins.top, margins.left, srcCentreH,
    x, y + margins.top, margins.left, destCentreH);

  { Right side }
  sprRegionStretch(
    texHandle,
    GetTexWidth(texHandle) - margins.right, margins.top, margins.right, srcCentreH,
    x + width - margins.right, y + margins.top, margins.right, destCentreH);

  { Corners }
  sprRegion(texHandle, 0, 0, margins.left, margins.top, x, y);
  sprRegion(texHandle, GetTexWidth(texHandle) - margins.right, 0, margins.right, margins.top, x + width - margins.right, y);
  sprRegion(texHandle, 0, GetTexHeight(texHandle) - margins.bottom, margins.left, margins.bottom, x, y + height - margins.bottom);
  sprRegion(texHandle, GetTexWidth(texHandle) - margins.right, GetTexHeight(texHandle) - margins.bottom, margins.right, margins.bottom, x + width - margins.right, y + height - margins.bottom);
end;


procedure OnPreload;
begin
  texCursor := RequestImage('assets/images/cursor.png');
  texHandCursor := RequestImage('assets/images/hand.png');

  fontBold := RequestBMFont('assets/fonts/p92_sans_8_bold.txt');

  texDosuEXE[0] := RequestImage('assets/images/dosu_1.png');
  texDosuEXE[1] := RequestImage('assets/images/dosu_2.png');

  { TODO: Migrate the asset loaders }
end;

procedure OnReady;
begin
  HideCursor;

  SetPromptBoxAssets(texPromptBG, texPromptButtonNormal, texPromptButtonNormal, texPromptButtonPressed);

  fontBlack := CloneBMFont(GetDefaultFontHandle);

  ReplaceColour(
    BorrowBMFontPtr(fontBlack)^.texHandle,
    $FFFFFFFF, $FF000000);

  clicks := 0;
  showFPS.checked := true;

  { panicDisplay('This is a drill!'); }
end;

procedure Update;
begin
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then SignalDone;
  end;

  gameTime := gameTime + DeltaTime;
end;

procedure Draw;
var
  w: integer;
  s: string;
begin
  cls(CornflowerBlue);

{
  if ImageButton((vgaWidth - getImageWidth(texWinNormal)) div 2, 88, texWinNormal, texWinHovered, texWinPressed) then
    ShowPromptBox('Accept?', PromptTest);
}

  spr(tex9SliceNormal, 30, 30);
  spr(tex9SliceHovered, 60, 30);
  spr(tex9SlicePressed, 90, 30);

  SprNineSlice(
    tex9SliceNormal,
    100, 100, 60, 30, demoMargins
  );

  s := 'Clicks: ' + i32str(clicks);
  w := MeasureBMFont(GetDefaultFontHandle, s);
  TextLabel(s, (vgaWidth - w) div 2, 120);

  if showFPS.checked then DrawFPS;
end;

procedure Init;
var
  appConfig: TP92AppConfig;
begin
  appConfig := DefaultP92AppConfig;

  P92Start(appConfig);
end;


exports
  Init,
  OnPreload,
  OnReady,
  Update,
  Draw;

begin
  { Starting point is intentionally left empty }
end.

