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
  P92AssetRegistry, P92WasmHost, P92Tex, P92TexDraw, P92TexEffects,
  P92Keyboard, P92Mouse, P92AssetHandles, P92Geometry, P92Timing,
  P92VGA, P92Panic,
  P92IMGUI, P92IMGUIPromptBox, P92IMGUI9Slice,
  Assets;

const
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
    Spr(texHandCursor, GetMouseX - 5, GetMouseY - 1)
  else
    Spr(texCursor, GetMouseX, GetMouseY);
end;


procedure OnPreload;
begin
  texCursor := RequestImage('assets/images/cursor.png');
  texHandCursor := RequestImage('assets/images/hand.png');

  fontBold := RequestBMFont('assets/fonts/p92_sans_8_bold.txt');

  texDosuEXE[0] := RequestImage('assets/images/dosu_1.png');
  texDosuEXE[1] := RequestImage('assets/images/dosu_2.png');

  texWinNormal := RequestImage('assets/images/btn_normal.png');
  texWinHovered := RequestImage('assets/images/btn_hovered.png');
  texWinPressed := RequestImage('assets/images/btn_pressed.png');

  tex9SliceNormal := RequestImage('assets/images/9slice_normal.png');
  tex9SliceHovered := RequestImage('assets/images/9slice_hovered.png');
  tex9SlicePressed := RequestImage('assets/images/9slice_pressed.png');
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
  if lastEsc <> isKeyDown(SC_ESCAPE) then begin
    lastEsc := isKeyDown(SC_ESCAPE);

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

  Spr(tex9SliceNormal, 30, 30);
  Spr(tex9SliceHovered, 60, 30);
  Spr(tex9SlicePressed, 90, 30);

  { SprNineSlice(
    tex9SliceNormal,
    100, 100, 60, 30, demoMargins); }

  GUISetFont(fontBlack);

  s := 'Clicks: ' + i32str(clicks);

  if ButtonNineSlice(
      s,
      100, 100, demoMargins,
      tex9SliceNormal, tex9SliceHovered, tex9SlicePressed) then
    inc(clicks);

  GUISetFont(GetDefaultFontHandle);

  { w := MeasureBMFont(GetDefaultFontHandle, s);
  TextLabel(s, (vgaWidth - w) div 2, 120); }

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

