{
  Immediate GUI Implementation
  Part of Posit-92 framework
  By Hevanafa, 22-11-2025

  Based on my QB64 Immediate GUI implementation
}

library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, ImmedGui, Keyboard, Logger,
  Mouse, Panic, Shapes, Sounds,
  Timing, VGA,
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
  image: PBitmap;
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

procedure sprNineSlice(
  const imgHandle: longint;
  const x, y, width, height: integer;
  const margins: TNineSliceMargins);
var
  srcCentreW, srcCentreH: integer;
  destCentreW, destCentreH: integer;
begin
  if not isImageSet(imgHandle) then
    panicHalt('sprNineSlice: imgHandle is ' + i32str(imgHandle) + '!');

  srcCentreW := getImageWidth(imgHandle) - margins.left - margins.right;
  srcCentreH := getImageHeight(imgHandle) - margins.top - margins.bottom;
  destCentreW := width - margins.left - margins.right;
  destCentreH := height - margins.top - margins.bottom;

  { Middle fill }
  sprRegionStretch(imgHandle,
    margins.left, margins.top, srcCentreW, srcCentreH,
    x + margins.left, y + margins.top, destCentreW, destCentreH);
  
  { Top side }
  sprRegionStretch(imgHandle,
    margins.left, 0, srcCentreW, margins.top,
    x + margins.left, y, destCentreW, margins.top);
  
  { Bottom side }
  sprRegionStretch(imgHandle,
    margins.left, getImageHeight(imgHandle) - margins.bottom, srcCentreW, margins.bottom,
    x + margins.left, y + height - margins.bottom, destCentreW, margins.bottom);

  { Left side }
  sprRegionStretch(imgHandle,
    0, margins.top, margins.left, srcCentreH,
    x, y + margins.top, margins.left, destCentreH);

  { Right side }
  sprRegionStretch(imgHandle,
    getImageWidth(imgHandle) - margins.right, margins.top, margins.right, srcCentreH,
    x + width - margins.right, y + margins.top, margins.right, destCentreH);

  { Corners }
  sprRegion(imgHandle, 0, 0, margins.left, margins.top, x, y);
  sprRegion(imgHandle, getImageWidth(imgHandle) - margins.right, 0, margins.right, margins.top, x + width - margins.right, y);
  sprRegion(imgHandle, 0, getImageHeight(imgHandle) - margins.bottom, margins.left, margins.bottom, x, y + height - margins.bottom);
  sprRegion(imgHandle, getImageWidth(imgHandle) - margins.right, getImageHeight(imgHandle) - margins.bottom, margins.right, margins.bottom, x + width - margins.right, y + height - margins.bottom);
end;


procedure init;
begin
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;

  initImmediateGUI;
  guiSetFont(defaultFont, defaultFontGlyphs);
  setPromptBoxAssets(imgPromptBG, imgPromptButtonNormal, imgPromptButtonNormal, imgPromptButtonPressed);

  replaceColours(blackFont.imgHandle, $FFFFFFFF, $FF000000);

  clicks := 0;
  showFPS.checked := true;

  panicDisplay('This is a drill!');
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateGUILastMouseButton;
  updateMouse;
  updateGUIMouseZone;

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
  cls(CornflowerBlue);

{
  if ImageButton((vgaWidth - getImageWidth(imgWinNormal)) div 2, 88, imgWinNormal, imgWinHovered, imgWinPressed) then
    ShowPromptBox('Accept?', PromptTest);
}

  spr(img9SliceNormal, 30, 30);
  spr(img9SliceHovered, 60, 30);
  spr(img9SlicePressed, 90, 30);

  sprNineSlice(
    img9SliceNormal,
    100, 100, 60, 30, demoMargins
  );

  s := 'Clicks: ' + i32str(clicks);
  w := measureBMFont(s, defaultFontGlyphs);
  TextLabel(s, (vgaWidth - w) div 2, 120);

  resetActiveWidget;
  drawMouse;

  if showFPS.checked then drawFPS;

  flush
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

