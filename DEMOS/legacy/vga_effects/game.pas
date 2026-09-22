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
    DemoStatePhosphor,
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
  applyFilter: boolean;
  
  showDemoList: boolean;
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

  { case which of
    DemoStateBlur: applyBlur := true;
    DemoStateChromaticAberration: }
      applyFilter := true;
    { else
  end; }
end;

function getDemoStateName(const state: TDemoStates): string;
begin
  case state of
    DemoStateBlur:
      result := 'Blur';
    DemoStateChromaticAberration:
      result := 'Chromatic Aberration';
    DemoStatePhosphor:
      result := 'Phosphor';
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

  showDemoList := true;
  demoListState.x := 10;
  demoListState.y := 10;

  for a:=0 to ord(DemoStateCount) - 1 do
    demoListItems[a] := getDemoStateName(TDemoStates(a));

  { beginDemoState(TDemoStates(0)) }
  beginDemoState(DemoStatePhosphor)

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
      applyFilter := not applyFilter;
  end;

  if lastTab <> isKeyDown(SC_TAB) then begin
    lastTab := isKeyDown(SC_TAB);
    if lastTab then showDemoList := not showDemoList;
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

  if demoListState.selectedIndex = ord(DemoStatePhosphor) then
    cls(black)
  else
    cls(CornflowerBlue);

  case TDemoStates(demoListState.selectedIndex) of
    DemoStateBlur: begin
      spr(imgDreamscapeCrossing, 0, 0);
      if applyFilter then applyFullBoxBlur(1);
    end;
    DemoStateChromaticAberration: begin
      spr(imgArkRoad, 0, 0);
      if applyFilter then applyFullChromabe;
    end;
    DemoStatePhosphor: begin
      spr(imgPipBoy, 0, 0);
      if applyFilter then applyFullPhosphor(1);
    end;
    else
  end;

  { Begin HUD }

  if showDemoList then
    ListView(demoListItems, demoListState);

  case TDemoStates(demoListState.selectedIndex) of
    DemoStateBlur:
      printBlack('Spacebar - Toggle blur', 10, vgaHeight - 20);
    DemoStateChromaticAberration:
      printDefault('Spacebar - Toggle chromatic aberration', 10, vgaHeight - 20);
    DemoStatePhosphor:
      printDefault('Spacebar - Toggle phosphor effect', 10, vgaHeight - 20);
    else
  end;

  case TDemoStates(demoListState.selectedIndex) of
    DemoStateBlur:
      s := 'Art by [Unknown Artist]';
    DemoStateChromaticAberration:
      s := 'Art by Kevin Hong';
    else s := ''
  end;
  w := measureDefault(s);
  printBlack(s, (vgaWidth - w) - 10, vgaHeight - 30);

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

