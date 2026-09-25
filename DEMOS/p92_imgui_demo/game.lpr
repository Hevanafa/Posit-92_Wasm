{
  Immediate GUI Implementation
  Part of Posit-92 game engine

  Based on my QB64 Immediate GUI implementation

  Mixins: bmfont
}

library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  { SysUtils, }  { it's possible to use format() but I would rather not }

  P92Core, P92Fonts, P92WasmHost, P92AssetRegistry, P92BMFont,
  P92Conversions, P92FPS, P92Graphics, P92Tex, P92TexDraw,
  P92TexEffects, P92Loading, P92Logger,
  P92Keyboard, P92Mouse, P92WasmHeap, P92Panic, P92Geometry,
  P92Timing, P92VGA, P92Colour,
  P92IMGUI, P92IMGUIPromptBox, P92IMGUI9Slice,
  Assets;

const
  CornflowerBlue = $FF6495ED;
  SemitransparentBlack = $80000000;

  demoMargins: TNineSliceMargins = (top: 8; right: 8; bottom: 8; left: 8);

  PromptKeyTest = 'TestPrompt';

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  clicks: word;
  showFPS: boolean;

  listItems: array of string;
  listState: TListViewState;

  sliderValue: smallint;

procedure DrawFPS;
begin
  PrintDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  if HasHoveredWidget then
    Spr(texHandCursor, GetMouseX - 5, GetMouseY - 1)
  else
    Spr(texCursor, GetMouseX, GetMouseY);
end;

procedure OnPreload;
begin
  texCursor := RequestImage('assets/images/cursor.png');
  texHandCursor := RequestImage('assets/images/hand.png');

  texDosuEXE[0] := RequestImage('assets/images/dosu_1.png');
  texDosuEXE[1] := RequestImage('assets/images/dosu_2.png');

  texWinNormal := RequestImage('assets/images/btn_normal.png');
  texWinHovered := RequestImage('assets/images/btn_hovered.png');
  texWinPressed := RequestImage('assets/images/btn_pressed.png');

  texPromptBG := RequestImage('assets/images/prompt_bg.png');
  texPromptButtonNormal := RequestImage('assets/images/btn_prompt_normal.png');
  texPromptButtonPressed := RequestImage('assets/images/btn_prompt_pressed.png');

  tex9SliceNormal := RequestImage('assets/images/9slice_normal.png');
  tex9SliceHovered := RequestImage('assets/images/9slice_hovered.png');
  tex9SlicePressed := RequestImage('assets/images/9slice_pressed.png');

  fontRegular := RequestBMFont('assets/fonts/p92_sans_8_regular.txt');
  fontBold := RequestBMFont('assets/fonts/p92_sans_8_bold.txt');
end;

procedure OnReady;
var
  a: word;
begin
  { Initialise game state here }
  hideCursor;

  gameTime := 0.0;

  fontBlack := CloneBMFont(fontRegular);
  ReplaceColour(BorrowBMFontPtr(fontBlack)^.texHandle, $FFFFFFFF, $FF000000);

  SetPromptBoxAssets(texPromptBG, texPromptButtonNormal, texPromptButtonNormal, texPromptButtonPressed);

  clicks := 0;
  showFPS := false;

  fontBlack := CloneBMFont(GetDefaultFontHandle);

  ReplaceColour(
    BorrowBMFontPtr(fontBlack)^.texHandle,
    $FFFFFFFF, $FF000000);

  SetLength(listItems, 3);
  for a:=0 to High(listItems) do
    listItems[a] := 'ListItem ' + i32str(a + 1);

  listState.x := 10;
  listState.y := 10;
  listState.selectedIndex := 0;
end;


procedure Update;
begin
  if lastEsc <> IsKeyDown(SC_ESCAPE) then begin
    lastEsc := IsKeyDown(SC_ESCAPE);

    if lastEsc then begin
      WriteLog('ESC is pressed!');
      signalDone
    end;
  end;

  { Used by prompt box }
  SetClickConsumed(false);

  gameTime := gameTime + DeltaTime
end;

procedure Draw;
var
  w: integer;
  s: string;
begin
  Cls($FF6495ED);

  GuiSetFont(fontBlack);

  if Button('Click me!', 180, 88) then
    inc(clicks);

  if ImageButton(240, 88, texWinNormal, texWinHovered, texWinPressed) then
    inc(clicks);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(texDosuEXE[1], 148, 88)
  else
    spr(texDosuEXE[0], 148, 88);

  { SprStretch(texDosuEXE[0], 100, 80, 24, 48); }

  SprTint(texDosuEXE[0], 100, 80, HSVtoRGB(frac(gameTime), 1.0, 1.0));

  GuiSetFont(fontRegular);
  Slider(120, 40, 100, sliderValue, 0, 100);
  TextLabel('Slider value: ' + i32str(sliderValue), 120, 30);

  { Migrated from the prompt box demo }

  if UnderButton('Under button', 280, 20) then
    inc(clicks);

  if UnderImageButton(
    (vgaWidth - GetTexWidth(texWinNormal)) div 2, 88,
    texWinNormal, texWinHovered, texWinPressed) then
      ShowPromptBox('Accept?', PromptKeyTest);

  case PromptBox of
    PromptResultYes:
      case GetPromptKey of
        PromptKeyTest: inc(clicks, 100);
      end;
    PromptResultNo:;
    else
  end;

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

  { HUD }

  s := 'Clicks: ' + i32str(clicks);
  w := GuiMeasureText(s);
  TextLabel(s, (VGAWidth - w) div 2, 120);

  GuiSetFont(fontBold);
  s := 'Bold font';
  w := GuiMeasureText(s);
  TextLabel(s, (VGAWidth - w) div 2, 140);

  GuiSetFont(fontRegular);
  ProgressBar(10, 80, 80, 10, 0.75);
  ProgressBarLabelled(10, 100, 80, 10, 0.75);
  Checkbox('Show FPS', 10, 60, showFPS);

  ListView(listItems, listState);

  { TextLabelWrap('This is a very long text!', 10, 160, 100); }
  { TextLabelWrap('This is a very long supercalifragilisticexpialidocious third line!', 10, 160, 100); }
  TextLabelWrap('1st line'#13#10'2nd line'#10'3rd longer line', 10, 160, 100);

  { Debug }
  {
  TextLabel('Hot widget: ' + i32str(GetHotWidget), 10, 10);
  TextLabel('Active widget: ' + i32str(GetActiveWidget), 10, 20);
  }

  DrawMouse;

  if showFPS then DrawFPS;
end;

procedure Init;
var
  config: TP92AppConfig;
begin
  config := DefaultP92AppConfig;

  config.LoadDefaultCursor := false;

  P92Start(config);
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

