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
  SysUtils,
  P92Core, P92Fonts, P92WasmHost, P92AssetRegistry, P92BMFont,
  P92Conversions, P92FPS, P92Graphics, P92Tex, P92TexDraw,
  P92TexEffects, P92ImmediateGUI, P92Loading, P92Logger,
  P92Keyboard, P92Mouse, P92WasmHeap, P92Panic, P92Geometry,
  P92Timing, P92VGA, P92Colour,
  Assets;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  clicks: word;
  showFPS: TCheckboxState;

  listItems: array of string;
  listState: TListViewState;

  sliderValue: TSliderState;

procedure DrawFPS;
begin
  PrintDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  if HasHoveredWidget then
    Spr(imgHandCursor, GetMouseX - 5, GetMouseY - 1)
  else
    Spr(imgCursor, GetMouseX, GetMouseY);
end;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');
  imgHandCursor := RequestImage('assets/images/hand.png');

  imgDosuExe[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuExe[1] := RequestImage('assets/images/dosu_2.png');

  imgWinNormal := RequestImage('assets/images/btn_normal.png');
  imgWinHovered := RequestImage('assets/images/btn_hovered.png');
  imgWinPressed := RequestImage('assets/images/btn_pressed.png');

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

  clicks := 0;
  showFPS.checked := false;

  SetLength(listItems, 3);
  for a:=0 to High(listItems) do
    listItems[a] := format('ListItem %d', [a + 1]);

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

  if ImageButton(240, 88, imgWinNormal, imgWinHovered, imgWinPressed) then
    inc(clicks);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  { SprStretch(imgDosuEXE[0], 100, 80, 24, 48); }

  SprTint(imgDosuEXE[0], 100, 80, HSVtoRGB(frac(gameTime), 1.0, 1.0));

  GuiSetFont(fontRegular);
  Slider(120, 40, 100, sliderValue, 0, 100);
  TextLabel('Slider value: ' + i32str(sliderValue.value), 120, 30);

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

  DrawMouse;

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

