{
  Immediate GUI Implementation
  Part of Posit-92 game engine

  Based on my QB64 Immediate GUI implementation
}

library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  SysUtils,
  EngineCore, EngineFonts, WasmHost,
  BMFont, Conv, FPS, Graphics,
  ImgRef, ImgRefFast, SprEffects,
  ImmediateGui,
  Keyboard, Loading, Logger, Mouse,
  Panic, Shapes, Timing, VGA,
  Assets;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Init your game state here }
  actualGameState: TGameStates;
  gameTime: double;
  clicks: word;
  showFPS: TCheckboxState;

  listItems: array of string;
  listState: TListViewState;

  sliderValue: TSliderState;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure hideCursor; external 'env' name 'hideCursor';
procedure hideLoadingOverlay; external 'env' name 'hideLoadingOverlay';
procedure loadAssets; external 'env' name 'loadAssets';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  if hasHoveredWidget then
    spr(imgHandCursor, mouseX - 5, mouseY - 1)
  else
    spr(imgCursor, mouseX, mouseY);
end;

procedure BeginLoadingState;
begin
  actualGameState := GameStateLoading;
  loadAssets
end;

{ TODO: Remove this }
procedure replaceColours(const imgHandle: longint; const oldColour, newColour: longword);
var
  a, b: word;
  image: PImageRef;
begin
  if not isImageSet(imgHandle) then begin
    writeLog('replaceColours: Unset imgHandle: ' + i32str(imgHandle));
    exit
  end;

  image := getImagePtr(imgHandle);

  for b:=0 to image^.height - 1 do
  for a:=0 to image^.width - 1 do
    if unsafeSprPget(image, a, b) = oldColour then
      unsafeSprPset(image, a, b, newColour);
end;

procedure BeginPlayingState;
var
  a: word;
begin
  { Initialise game state here }
  hideCursor;

  actualGameState := GameStatePlaying;
  gameTime := 0.0;

  initImmediateGUI;
  guiSetFont(defaultFont, defaultFontGlyphs);

  replaceColours(blackFont.imgHandle, $FFFFFFFF, $FF000000);

  clicks := 0;
  showFPS.checked := false;

  SetLength(listItems, 3);
  for a:=0 to High(listItems) do
    listItems[a] := format('ListItem %d', [a + 1]);

  listState.x := 10;
  listState.y := 10;
  listState.selectedIndex := 0;
end;


procedure OnReady;
begin
  BeginPlayingState
end;

procedure Update;
begin
  UpdateDeltaTime;
  IncrementFPS;

  updateGUILastMouseButton;
  UpdateMouse;
  updateGUIMousePoint;

  { Your Update logic here }
  if lastEsc <> IsKeyDown(SC_ESC) then begin
    lastEsc := IsKeyDown(SC_ESC);

    if lastEsc then begin
      WriteLog('ESC is pressed!');
      signalDone
    end;
  end;

  gameTime := gameTime + DeltaTime;

  resetWidgetIndices
end;

procedure Draw;
var
  w: integer;
  s: string;
begin
  if actualGameState = GameStateLoading then begin
    RenderLoadingScreen;
    exit
  end;

  Spr(imgCursor, 10, 100);

  Cls($FF6495ED);

  guiSetFont(blackFont, blackFontGlyphs);
  if Button('Click me!', 180, 88, 50, 24) then
    inc(clicks);

  if ImageButton(240, 88, imgWinNormal, imgWinHovered, imgWinPressed) then
    inc(clicks);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  sprStretch(imgDosuEXE[0], 100, 80, 24, 48);

  guiSetFont(defaultFont, defaultFontGlyphs);
  Slider(120, 40, 100, sliderValue, 0, 100);
  TextLabel('Slider value: ' + i32str(sliderValue.value), 120, 30);

  s := 'Clicks: ' + i32str(clicks);
  w := guiMeasureText(s);
  TextLabel(s, (vgaWidth - w) div 2, 120);

  guiSetFont(picotronFont, picotronFontGlyphs);
  s := 'Picotron font';
  w := guiMeasureText(s);
  TextLabel(s, (vgaWidth - w) div 2, 140);

  guiSetFont(defaultFont, defaultFontGlyphs);
  ProgressBar(10, 80, 80, 10, 0.75);
  ProgressBarLabelled(10, 100, 80, 10, 0.75);
  Checkbox('Show FPS', 10, 60, showFPS);

  ListView(listItems, listState);

  { TextLabelWrap('This is a very long text!', 10, 160, 100); }
  { TextLabelWrap('This is a very long supercalifragilisticexpialidocious third line!', 10, 160, 100); }
  TextLabelWrap('1st line'#13#10'2nd line'#10'3rd longer line', 10, 160, 100);

  resetActiveWidget;

  drawMouse;

  if showFPS.checked then drawFPS;

  VgaUpload;
  VgaPresent
end;

exports
  { Main game procedures }
  BeginLoadingState,
  OnReady, Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

