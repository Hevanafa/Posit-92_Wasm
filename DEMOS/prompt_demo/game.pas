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

const
  SC_ESC = $01;
  SC_SPACE = $39;

  CornflowerBlue = $FF6495ED;
  SemitransparentBlack = $80000000;

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

  if ImageButton((vgaWidth - getImageWidth(imgWinNormal)) div 2, 88, imgWinNormal, imgWinHovered, imgWinPressed) then
    ShowPromptBox('Accept?', PromptTest);

  s := 'Clicks: ' + i32str(clicks);
  w := measureBMFont(s, defaultFontGlyphs);
  TextLabel(s, (vgaWidth - w) div 2, 120);

  case PromptBox of
    PromptYes:
      case promptKey of
        PromptTest: inc(clicks, 100);
      end;
    PromptNo:;
    else
  end;

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

