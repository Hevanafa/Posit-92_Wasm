{
  Immediate GUI Implementation
  Part of Posit-92 framework
  By Hevanafa, 22-11-2025

  Based on my QB64 Immediate GUI implementation
}

library Game;

{$Mode ObjFPC}

uses
  BMFont, Conv, FPS, Graphics,
  ImgRef, ImgRefFast, ImmedGui,
  Keyboard, Logger, Mouse,
  Panic, Shapes, Timing,
  WasmMemMgr, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;


var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  clicks: word;
  showFPS: TCheckboxState;

  listItems: array[0..2] of string;
  listState: TListViewState;

  sliderValue: TSliderState;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

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


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
var
  a: integer;
begin
  { Initialise game state here }
  hideCursor;

  initImmediateGUI;
  guiSetFont(defaultFont, defaultFontGlyphs);

  replaceColours(blackFont.imgHandle, $FFFFFFFF, $FF000000);

  clicks := 0;

  for a:=0 to high(listItems) do
    listItems[a] := 'ListItem' + i32str(a);
  
  listState.x := 10;
  listState.y := 10;
  listState.selectedIndex := 0;
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateGUILastMouseButton;
  updateMouse;
  updateGUIMousePoint;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  gameTime := gameTime + dt;

  resetWidgetIndices
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  guiSetFont(blackFont, blackFontGlyphs);
  if Button('Click me!', 180, 88, 50, 24) then
    inc(clicks);

  if ImageButton(240, 88, imgWinNormal, imgWinHovered, imgWinPressed) then
    inc(clicks);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  { spr(imgDosuEXE[0], 100, 80); }
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

  resetActiveWidget;

  drawMouse;

  if showFPS.checked then drawFPS;

  vgaFlush
end;

exports
  { Main game procedures }
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

