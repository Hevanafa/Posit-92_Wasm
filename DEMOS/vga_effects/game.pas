library Game;

{$Mode ObjFPC}
{$H-}
{$J-}

uses
  BMFont, Conv, FPS, Fullscreen,
  Loading, Logger, Keyboard, Mouse,
  ImgRef, ImgRefFast, ImmedGui,
  PostProc, Timing, VGA, WasmMemMgr, WasmHeap,
  Assets;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );
  TDemoStates = (
    DemoStateBlur,
    DemoStateChromaticAberration,
    DemoStateCount
  );

const
  SC_ESC = $01;
  SC_SPACE = $39;
  SC_TAB = $0F;

  CornflowerBlue = $FF6495ED;
  Black = $FF000000;

var
  lastEsc, lastSpacebar, lastTab: boolean;

  { Game state variables }
  actualGameState: TGameStates;
  gameTime: double;
  applyBlur, showFilter: boolean;

  demoListState: TListViewState;
  demoListItems: array[0..ord(DemoStateCount) - 1] of string;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure hideCursor; external 'env' name 'hideCursor';
procedure hideLoadingOverlay; external 'env' name 'hideLoadingOverlay';
procedure loadAssets; external 'env' name 'loadAssets';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure beginDemoState(const which: TDemoStates);
begin
  demoListState.selectedIndex := ord(which);

  case which of
    DemoStateBlur: applyBlur := true;
    DemoStateChromaticAberration:
      showFilter := true;
    else
  end;
end;

function getDemoStateName(const state: TDemoStates): string;
begin
  case state of
    DemoStateBlur:
      result := 'Blur';
    DemoStateChromaticAberration:
      result := 'Chromatic Aberration';
    else result := 'Unknown state: ' + i32str(ord(state));
  end;
end;

procedure beginLoadingState;
begin
  actualGameState := GameStateLoading;
  fitCanvas;
  loadAssets
end;

procedure beginPlayingState;
var
  a: word;
begin
  hideCursor;
  fitCanvas;

  initImmediateGUI;
  guiSetFont(defaultFont, defaultFontGlyphs);

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;

  lastTab := false;

  demoListState.x := 10;
  demoListState.y := 10;

  for a:=0 to ord(DemoStateCount) - 1 do
    demoListItems[a] := getDemoStateName(TDemoStates(a));

  { beginDemoState(TDemoStates(0)) }
  beginDemoState(DemoStateChromaticAberration)

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

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then signalDone;
  end;

  if lastSpacebar <> isKeyDown(SC_SPACE) then begin
    lastSpacebar := isKeyDown(SC_SPACE);
    if lastSpacebar then
      applyBlur := not applyBlur;
  end;

  if lastTab <> isKeyDown(SC_TAB) then begin
    lastTab := isKeyDown(SC_TAB);
    { TODO: Toggle list view }
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

  case TDemoStates(demoListState.selectedIndex) of
    DemoStateBlur:
      spr(imgDreamscapeCrossing, 0, 0);
    DemoStateChromaticAberration:
      spr(imgArkRoad, 0, 0);
  end;

  if applyBlur then applyFullBoxBlur(1);
  if showFilter then applyFullChromabe;

  { Begin HUD }
  ListView(demoListItems, demoListState);

  case TDemoStates(demoListState.selectedIndex) of
    DemoStateBlur:
      printBlack('Spacebar - Toggle blur', 10, vgaHeight - 20);
    DemoStateChromaticAberration:
      printDefault('Spacebar - Toggle chromatic aberration', 10, vgaHeight - 20);
  end;

  s := 'Art by [Unknown Artist]';
  w := measureDefault(s);
  printBlack(s, (vgaWidth - w) - 10, vgaHeight - 20);

  resetActiveWidget;

  drawFPS;
  drawMouse;
  vgaFlush
end;

exports
  beginLoadingState,
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.

