{
  Immediate GUI Implementation
  Part of Posit-92 game engine

  Based on my QB64 Immediate GUI implementation

  Mixins: bmfont, sound
}

library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  SysUtils,
  P92Core, P92Fonts, P92WasmHost, P92AssetRegistry,
  P92BMFont, P92Conversions, P92FPS, P92Graphics,
  P92Tex, P92TexDraw, P92TexEffects,
  P92ImmediateGUI, P92Loading, P92Logger,
  P92Keyboard, P92Mouse,
  P92Panic, P92Geometry, P92Timing, P92VGA,
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

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  if HasHoveredWidget then
    spr(imgHandCursor, mouseX - 5, mouseY - 1)
  else
    spr(imgCursor, mouseX, mouseY);
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

  RequestBMFont('assets/fonts/nokia_cellphone_fc_8.txt', @blackFont, @blackFontGlyphs);
  RequestBMFont('assets/fonts/picotron_8px.txt', @picotronFont, @picotronFontGlyphs);
end;

procedure OnReady;
var
  a: word;
begin
  { Initialise game state here }
  hideCursor;

  gameTime := 0.0;

  ReplaceColour(blackFont.texHandle, $FFFFFFFF, $FF000000);

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

  GuiSetFont(blackFont, blackFontGlyphs);
  if Button('Click me!', 180, 88, 50, 24) then
    inc(clicks);

  if ImageButton(240, 88, imgWinNormal, imgWinHovered, imgWinPressed) then
    inc(clicks);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  sprStretch(imgDosuEXE[0], 100, 80, 24, 48);

  GuiSetFont(DefaultFontPtr^, DefaultFontGlyphsPtr^);
  Slider(120, 40, 100, sliderValue, 0, 100);
  TextLabel('Slider value: ' + i32str(sliderValue.value), 120, 30);

  s := 'Clicks: ' + i32str(clicks);
  w := GuiMeasureText(s);
  TextLabel(s, (vgaWidth - w) div 2, 120);

  GuiSetFont(picotronFont, picotronFontGlyphs);
  s := 'Picotron font';
  w := GuiMeasureText(s);
  TextLabel(s, (vgaWidth - w) div 2, 140);

  GuiSetFont(DefaultFontPtr^, DefaultFontGlyphsPtr^);
  ProgressBar(10, 80, 80, 10, 0.75);
  ProgressBarLabelled(10, 100, 80, 10, 0.75);
  Checkbox('Show FPS', 10, 60, showFPS);

  ListView(listItems, listState);

  { TextLabelWrap('This is a very long text!', 10, 160, 100); }
  { TextLabelWrap('This is a very long supercalifragilisticexpialidocious third line!', 10, 160, 100); }
  TextLabelWrap('1st line'#13#10'2nd line'#10'3rd longer line', 10, 160, 100);

  DrawMouse;

  if showFPS.checked then drawFPS;
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

