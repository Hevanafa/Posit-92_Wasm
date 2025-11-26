library Game;

{$Mode TP}
{$B-}

uses Bitmap, Conv, FPS, ImmedGui,
  Keyboard, Lerp, Logger, Mouse,
  Panic, Shapes, Timing, VGA,
  SprFast, SprComp,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  { For movement }
  SC_W = $11;
  SC_A = $1E;
  SC_S = $1F;
  SC_D = $20;

  { For scaling }
  SC_UP = $48;
  SC_LEFT = $4B;
  SC_RIGHT = $4D;
  SC_DOWN = $50;

  SC_TAB = $0F;
  SC_PAGEUP = $49;
  SC_PAGEDOWN = $51;

  Black = $FF000000;
  White = $FFFFFFFF;
  Red = $FFFF5555;

  { DemoStates enum }
  DemoStateFullSprite = 0;
  DemoStateRegion = 1;
  DemoStateBlend = 2;
  DemoStateScaling = 3;
  DemoStateRegionScaling = 4;
  DemoStateFlip = 5;
  DemoStateRotation = 6;
  DemoStateLast = 6;
  { DemoStateCount = 7; }

var
  lastEsc: boolean;
  lastSpacebar: boolean;
  lastUp, lastRight, lastDown, lastLeft: boolean;
  lastTab, lastPageUp, lastPageDown: boolean;

  { Init your game state here }
  { actualDemoState: integer; }
  gameTime: double;
  showDemoList, lastShowDemoList: boolean;

  dosuZone: TRect;
  demoListStartX, demoListEndX: double;
  demoListLerpTimer: TLerpTimer;
  demoListItems: array[0..DemoStateLast] of string;
  demoListState: TListViewState;
  lastDemoState: integer;

  selectedFrame: integer;
  { Use SprFlips enum }
  spriteFlip: integer;
  spriteRotation: double;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  { spr(imgCursor, mouseX, mouseY) }
  spr(imgHandCursor, mouseX - 5, mouseY - 1)
end;

procedure resetHeldKeys;
begin
  lastEsc := false;
  lastSpacebar := false;
  
  lastUp := false;
  lastRight := false;
  lastDown := false;
  lastLeft := false;

  lastTab := false;
  lastPageUp := false;
  lastPageDown := false;
end;

{ demoState: use DemoStates }
procedure changeState(const newState: integer);
begin
  { resetHeldKeys; }

  actualDemoState := newState;

  gameTime := 0.0;

  if (actualDemoState = DemoStateBlend) or (actualDemoState = DemoStateFlip) then begin
    dosuZone.x := (vgaWidth - getImageWidth(imgSlimeGirl)) / 2;
    dosuZone.y := (vgaHeight - getImageHeight(imgSlimeGirl)) / 2;
    dosuZone.width := getImageWidth(imgSlimeGirl);
    dosuZone.height := getImageHeight(imgSlimeGirl);

  end else if actualDemoState = DemoStateRotation then begin
    dosuZone.x := vgaWidth / 2;
    dosuZone.y := vgaHeight / 2;

  end else begin
    dosuZone.x := 148;
    dosuZone.y := 88;
    dosuZone.width := 24;
    dosuZone.height := 24;
  end;

  selectedFrame := 0;
  spriteFlip := SprFlipHorizontal;
  spriteRotation := 0.0;
end;

function getDemoStateName(const state: integer): string;
var
  result: string;
begin
  case state of
    DemoStateFullSprite:
      result := 'Full sprite';
    DemoStateRegion:
      result := 'Sprite region';
    DemoStateBlend:
      result := 'Alpha blending';
    DemoStateScaling:
      result := 'Sprite scaling';
    DemoStateRegionScaling:
      result := 'Region scaling';
    DemoStateFlip:
      result := 'Sprite flipping';
    DemoStateRotation:
      result := 'Sprite rotation';
    else
      result := 'Unknown DemoState: ' + i32str(state);
  end;

  getDemoStateName := result
end;


procedure init;
begin
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
var
  a: word;
begin
  { Initialise game state here }
  hideCursor;

  guiSetFont(defaultFont, defaultFontGlyphs);

  showDemoList := true;

  for a:=0 to DemoStateLast do
    demoListItems[a] := getDemoStateName(a + 1);

  demoListState.x := 10;
  demoListState.y := 10;
  demoListState.selectedIndex := 0;

  changeState(DemoStateScaling);
end;

procedure printCentred(const text: string; const y: integer);
var
  w: word;
begin
  w := measureDefault(text);
  printDefault(text, (vgaWidth - w) div 2, y);
end;


procedure update;
var
  perc, x: double;
begin
  updateDeltaTime;
  incrementFPS;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  if lastSpacebar <> isKeyDown(SC_SPACE) then begin
    lastSpacebar := isKeyDown(SC_SPACE);

    if lastSpacebar then begin
      inc(selectedFrame);
      if selectedFrame > 3 then selectedFrame := 0;
    end;
  end;

  if lastTab <> isKeyDown(SC_TAB) then begin
    lastTab := isKeyDown(SC_TAB);

    if lastTab then showDemoList := not showDemoList;
  end;

  if lastPageUp <> isKeyDown(SC_PAGEUP) then begin
    lastPageUp := isKeyDown(SC_PAGEUP);

    if lastPageUp then begin
      dec(demoListState.selectedIndex);
      
      if demoListState.selectedIndex < 0 then
        demoListState.selectedIndex := DemoStateLast;
        
      changeState(demoListState.selectedIndex)
    end;
  end;

  if lastPageDown <> isKeyDown(SC_PAGEDOWN) then begin
    lastPageDown := isKeyDown(SC_PAGEDOWN);

    if lastPageDown then begin
      inc(demoListState.selectedIndex);

      if demoListState.selectedIndex > DemoStateLast then
        demoListState.selectedIndex := 0;

      changeState(demoListState.selectedIndex)
    end;
  end;

  if isKeyDown(SC_W) then dosuZone.y := dosuZone.y - 1;
  if isKeyDown(SC_S) then dosuZone.y := dosuZone.y + 1;

  if isKeyDown(SC_A) then dosuZone.x := dosuZone.x - 1;
  if isKeyDown(SC_D) then dosuZone.x := dosuZone.x + 1;

  if (demoListState.selectedIndex = DemoStateScaling) or (demoListState.selectedIndex = DemoStateRegionScaling) then begin
    if isKeyDown(SC_UP) and (dosuZone.height > 1.0) then dosuZone.height := dosuZone.height - 1;
    if isKeyDown(SC_DOWN) then dosuZone.height := dosuZone.height + 1;

    if isKeyDown(SC_RIGHT) then dosuZone.width := dosuZone.width + 1;
    if isKeyDown(SC_LEFT) and (dosuZone.width > 1.0) then dosuZone.width := dosuZone.width - 1;
  end;

  if demoListState.selectedIndex = DemoStateFlip then begin
    if lastUp <> isKeyDown(SC_UP) then begin
      lastUp := isKeyDown(SC_UP);

      if lastUp then spriteFlip := spriteFlip xor SprFlipVertical;
    end;
    if lastDown <> isKeyDown(SC_DOWN) then begin
      lastDown := isKeyDown(SC_DOWN);

      if lastDown then spriteFlip := spriteFlip xor SprFlipVertical;
    end;

    if lastLeft <> isKeyDown(SC_LEFT) then begin
      lastLeft := isKeyDown(SC_LEFT);

      if lastLeft then spriteFlip := spriteFlip xor SprFlipHorizontal;
    end;
    if lastRight <> isKeyDown(SC_RIGHT) then begin
      lastRight := isKeyDown(SC_RIGHT);

      if lastRight then spriteFlip := spriteFlip xor SprFlipHorizontal;
    end;
  end;

  if demoListState.selectedIndex = DemoStateRotation then begin
    if isKeyDown(SC_LEFT) then
      spriteRotation := spriteRotation - pi / 30.0;
    if isKeyDown(SC_RIGHT) then
      spriteRotation := spriteRotation + pi / 30.0;
  end;

  if lastShowDemoList <> showDemoList then begin
    lastShowDemoList := showDemoList;

    perc := getLerpPerc(demoListLerpTimer, getTimer);
    x := lerpEaseOutQuad(demoListStartX, demoListEndX, perc);
    
    if lastShowDemoList then begin
      demoListStartX := x;
      demoListEndX := 10;
    end else begin
      demoListStartX := x;
      demoListEndX := -120;
    end;

    initLerp(demoListLerpTimer, getTimer, 0.4);
  end;

  gameTime := gameTime + dt
end;


procedure draw;
var
  perc, x: double;
begin
  cls($FF6495ED);

  { writeLogF32(gameTime * 4); }

  { if showDemoList then drawDemoList; }
  if isLerpComplete(demoListLerpTimer, getTimer) then
    x := demoListEndX
  else begin
    perc := getLerpPerc(demoListLerpTimer, getTimer);
    x := lerpEaseOutQuad(demoListStartX, demoListEndX, perc);
  end;
  
  { ListView(trunc(x), 10, demoListItems, actualDemoState - 1); }
  demoListState.x := trunc(x);
  ListView(demoListItems, demoListState);

  case demoListState.selectedIndex of
    DemoStateFullSprite: begin
      spr(imgDosuEXE[0], trunc(dosuZone.x), trunc(dosuZone.y));
      printCentred('WASD - Move', 120);
    end;

    DemoStateRegion: begin
      sprRegion(imgBlueEnemy,
        25 * selectedFrame, 0, 25, 25,
        trunc(dosuZone.x), trunc(dosuZone.y));

      printCentred('WASD - Move', 120);
      printCentred('Spacebar - Change frame', 130);
    end;

    DemoStateBlend: begin
      sprBlend(imgSlimeGirl, trunc(dosuZone.x), trunc(dosuZone.y));
      printCentred('WASD - Move', 120);
    end;

    DemoStateScaling: begin
      with dosuZone do
        if (trunc(gameTime * 4) and 1) > 0 then
          sprStretch(imgDosuEXE[1], trunc(x), trunc(y), trunc(width), trunc(height))
        else
          sprStretch(imgDosuEXE[0], trunc(x), trunc(y), trunc(width), trunc(height));

      printCentred('WASD - Move', 120);
      printCentred('Arrow keys - Resize', 130);
    end;

    DemoStateRegionScaling: begin
      sprRegionStretch(imgBlueEnemy,
        25 * selectedFrame, 0, 25, 25,
        trunc(dosuZone.x), trunc(dosuZone.y), trunc(dosuZone.width), trunc(dosuZone.height));

      printCentred('WASD - Move', 120);
      printCentred('Arrow keys - Resize', 130);
    end;

    DemoStateFlip: begin
      sprFlip(imgSlimeGirl, trunc(dosuZone.x), trunc(dosuZone.y), spriteFlip);
      printCentred('WASD - Move', 120);
      printCentred('Arrow keys - Flip', 130);
    end;

    DemoStateRotation: begin
      sprRotate(imgSlimeGirl, trunc(dosuZone.x), trunc(dosuZone.y), spriteRotation);
{
      rect(
        trunc(dosuZone.x - getImageWidth(imgSlimeGirl) / 2),
        trunc(dosuZone.y - getImageHeight(imgSlimeGirl) / 2),
        trunc(dosuZone.x + getImageWidth(imgSlimeGirl) / 2),
        trunc(dosuZone.y + getImageHeight(imgSlimeGirl) / 2),
        white);
}
      printCentred('WASD - Move', 120);
      printCentred('Left / right - Rotate', 130);
    end

    else begin
      if (trunc(gameTime * 4) and 1) > 0 then
        spr(imgDosuEXE[1], trunc(dosuZone.x), trunc(dosuZone.y))
      else
        spr(imgDosuEXE[0], trunc(dosuZone.x), trunc(dosuZone.y));

      printCentred('(Not implemented)', 130);
    end
  end;

  if showDemoList then begin
    printDefault('TAB - Hide the list of demos', 8, vgaHeight - 28);
    printDefault('Page up / down - Choose between demos', 8, vgaHeight - 18);
  end else
    printDefault('TAB - Show the list of demos', 8, vgaHeight - 18);

  drawMouse;
  drawFPS;

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

