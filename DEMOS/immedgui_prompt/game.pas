{
  Immediate GUI Implementation
  Part of Posit-92 game engine
  By Hevanafa, 22-11-2025

  Based on my QB64 Immediate GUI implementation
}

library Game;

{$Mode ObjFPC}

uses
  BMFont, Conv, FPS, Fullscreen,
  Graphics, Loading,
  ImgRef, ImgRefFast, ImmedGui,
  Keyboard, Logger, Mouse,
  Panic, Shapes, SprEffects, Timing,
  WasmMemMgr, VGA,
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

  CornflowerBlue = $FF6495ED;
  SemitransparentBlack = $80000000;

  { Prompts enum }
  PromptTest = 1;

var
  lastEsc: boolean;

  { Game state variables }
  actualGameState: TGameStates;
  gameTime: double;
  clicks: word;
  showFPS: TCheckboxState;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
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

procedure beginLoadingState;
begin
  actualGameState := GameStateLoading;
  fitCanvas;
  loadAssets
end;

procedure beginPlayingState;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;

  initImmediateGUI;
  guiSetFont(defaultFont, defaultFontGlyphs);
  setPromptBoxAssets(imgPromptBG, imgPromptButtonNormal, imgPromptButtonNormal, imgPromptButtonPressed);

  replaceColour(blackFont.imgHandle, $FFFFFFFF, $FF000000);

  clicks := 0;
  showFPS.checked := true;
end;


procedure init;
begin
  initHeapMgr;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
begin
  beginPlayingState
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
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;
  
  cls(CornflowerBlue);

  if ImageButton((vgaWidth - getImageWidth(imgWinNormal)) div 2, 88, imgWinNormal, imgWinHovered, imgWinPressed) then
    ShowPromptBox('Accept?', PromptTest);

  s := 'Clicks: ' + i32str(clicks);
  w := measureBMFont(defaultFontGlyphs, s);
  TextLabel(s, (vgaWidth - w) div 2, 120);

  case PromptBox of
    PromptYes:
      case getPromptKey of
        PromptTest: inc(clicks, 100);
      end;
    PromptNo:;
    else
  end;

  resetActiveWidget;
  drawMouse;

  if showFPS.checked then drawFPS;

  vgaFlush
end;

exports
  { Main game procedures }
  beginLoadingState,
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.

