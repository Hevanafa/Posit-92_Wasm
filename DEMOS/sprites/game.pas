library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Conversions, P92FPS, P92AssetRegistry, P92WasmHost, P92WasmHeap,
  P92IMGUI, P92Geometry, P92Fonts,
  P92Tex, P92TexDraw, P92TexComp,
  P92Keyboard, P92Mouse, P92Easings,
  P92Logger, P92PostProc, P92Timing, P92VGA,
  Assets;

const
  Black = $FF000000;
  White = $FFFFFFFF;
  Red = $FFFF5555;

type
  TDemoState = (
    DemoStateFullSprite,
    DemoStateRegion,
    DemoStateBlend,
    DemoStateScaling,
    DemoStateRegionScaling,
    DemoStateFlip,
    DemoStateRotation
  );

var
  lastEsc: boolean;
  lastSpacebar: boolean;
  lastUp, lastRight, lastDown, lastLeft: boolean;
  lastTab, lastPageUp, lastPageDown: boolean;

  { Init your game state here }
  gameTime: double;
  showDemoList, lastShowDemoList: boolean;

  dosuZone: TZone;
  demoListStartX, demoListEndX: double;
  demoListLerpTimer: TEasingTimer;
  demoListItems: array[0..ord(high(TDemoState))] of string;
  demoListState: TListViewState;
  lastDemoIndex: TDemoState;

  selectedFrame: integer;
  { Use SprFlips enum }
  spriteFlip: integer;
  spriteRotation: double;

procedure DrawFPS;
begin
  PrintDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  if HasHoveredWidget then
    Spr(texHandCursor, GetMouseX - 5, GetMouseY - 1)
  else
    Spr(texCursor, GetMouseX, GetMouseY);
end;

function GetDemoStateName(const state: TDemoState): string;
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
      result := 'Unknown DemoState: ' + i32str(ord(state));
  end;
end;

procedure InitDemoState(const which: TDemoState);
begin
  gameTime := 0.0;

  if (which = DemoStateBlend)
    or (which = DemoStateFlip) then begin
    dosuZone.x := (vgaWidth - GetTexWidth(texSlimeGirl)) / 2;
    dosuZone.y := (vgaHeight - GetTexHeight(texSlimeGirl)) / 2;
    dosuZone.width := GetTexWidth(texSlimeGirl);
    dosuZone.height := GetTexHeight(texSlimeGirl);

  end else if which = DemoStateRotation then begin
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


procedure OnPreload;
begin
  texCursor := RequestImage('assets/images/cursor.png');
  texHandCursor := RequestImage('assets/images/hand.png');
  texSlimeGirl := RequestImage('assets/images/piyo_0426_slime_girl.png');
  texBlueEnemy := RequestImage('assets/images/blue_enemy.png');

  texDosuEXE[0] := RequestImage('assets/images/dosu_1.png');
  texDosuEXE[1] := RequestImage('assets/images/dosu_2.png');
end;

procedure OnReady;
var
  a: word;
begin
  HideCursor;

  { Initialise game state here }
  showDemoList := true;

  for a:=0 to ord(high(TDemoState)) do
    demoListItems[a] := GetDemoStateName(TDemoState(a));

  demoListState.x := 10;
  demoListState.y := 10;
  demoListState.selectedIndex := ord(low(TDemoState));

  InitDemoState(low(TDemoState));
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


procedure PrintCentred(const text: string; const y: integer);
var
  w: word;
begin
  w := measureDefault(text);
  printDefault(text, (vgaWidth - w) div 2, y);
end;


procedure Update;
var
  perc, x: double;
begin
  if lastEsc <> IsKeyDown(SC_ESCAPE) then begin
    lastEsc := IsKeyDown(SC_ESCAPE);

    if lastEsc then SignalDone;
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
        demoListState.selectedIndex := ord(high(TDemoState));
    end;
  end;

  if lastPageDown <> isKeyDown(SC_PAGEDOWN) then begin
    lastPageDown := isKeyDown(SC_PAGEDOWN);

    if lastPageDown then begin
      inc(demoListState.selectedIndex);

      if demoListState.selectedIndex > ord(high(TDemoState)) then
        demoListState.selectedIndex := 0;
    end;
  end;


  if isKeyDown(SC_W) then dosuZone.y := dosuZone.y - 1;
  if isKeyDown(SC_S) then dosuZone.y := dosuZone.y + 1;

  if isKeyDown(SC_A) then dosuZone.x := dosuZone.x - 1;
  if isKeyDown(SC_D) then dosuZone.x := dosuZone.x + 1;

  if (demoListState.selectedIndex = ord(DemoStateScaling))
    or (demoListState.selectedIndex = ord(DemoStateRegionScaling)) then begin
    if isKeyDown(SC_UP) and (dosuZone.height > 1.0) then dosuZone.height := dosuZone.height - 1;
    if isKeyDown(SC_DOWN) then dosuZone.height := dosuZone.height + 1;

    if isKeyDown(SC_RIGHT) then dosuZone.width := dosuZone.width + 1;
    if isKeyDown(SC_LEFT) and (dosuZone.width > 1.0) then dosuZone.width := dosuZone.width - 1;
  end;

  if demoListState.selectedIndex = ord(DemoStateFlip) then begin
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

  if demoListState.selectedIndex = ord(DemoStateRotation) then begin
    if isKeyDown(SC_LEFT) then
      spriteRotation := spriteRotation - pi / 30.0;
    if isKeyDown(SC_RIGHT) then
      spriteRotation := spriteRotation + pi / 30.0;
  end;

  if lastShowDemoList <> showDemoList then begin
    lastShowDemoList := showDemoList;

    perc := GetEasingPerc(demoListLerpTimer, getTimer);
    x := lerpEaseOutQuad(demoListStartX, demoListEndX, perc);
    
    if lastShowDemoList then begin
      demoListStartX := x;
      demoListEndX := 10;
    end else begin
      demoListStartX := x;
      demoListEndX := -120;
    end;

    InitEasing(demoListLerpTimer, getTimer, 0.4);
  end;

  if lastDemoIndex <> TDemoState(demoListState.selectedIndex) then begin
    lastDemoIndex := TDemoState(demoListState.selectedIndex);
    InitDemoState(lastDemoIndex)
  end;

  gameTime := gameTime + DeltaTime;
end;


procedure Draw;
var
  perc, x: double;
begin
  cls($FF6495ED);

  { writeLogF32(gameTime * 4); }

  { if showDemoList then drawDemoList; }

  if IsEasingComplete(demoListLerpTimer, getTimer) then
    x := demoListEndX
  else begin
    perc := GetEasingPerc(demoListLerpTimer, getTimer);
    x := lerpEaseOutQuad(demoListStartX, demoListEndX, perc);
  end;
  
  { ListView(trunc(x), 10, demoListItems, actualDemoState - 1); }
  demoListState.x := trunc(x);
  ListView(demoListItems, demoListState);

  case TDemoState(demoListState.selectedIndex) of
    DemoStateFullSprite: begin
      Spr(texDosuEXE[0], trunc(dosuZone.x), trunc(dosuZone.y));
      PrintCentred('WASD - Move', 120);
    end;

    DemoStateRegion: begin
      SprRegion(
        texBlueEnemy,
        25 * selectedFrame, 0,
        25, 24,
        trunc(dosuZone.x), trunc(dosuZone.y));

      PrintCentred('WASD - Move', 120);
      PrintCentred('Spacebar - Change frame', 130);
    end;

    DemoStateBlend: begin
      SprBlend(texSlimeGirl, trunc(dosuZone.x), trunc(dosuZone.y));
      PrintCentred('WASD - Move', 120);
    end;

    DemoStateScaling: begin
      with dosuZone do
        if (trunc(gameTime * 4) and 1) > 0 then
          SprStretch(texDosuEXE[1], trunc(x), trunc(y), trunc(width), trunc(height))
        else
          SprStretch(texDosuEXE[0], trunc(x), trunc(y), trunc(width), trunc(height));

      PrintCentred('WASD - Move', 120);
      PrintCentred('Arrow keys - Resize', 130);
    end;

    DemoStateRegionScaling: begin
      sprRegionStretch(texBlueEnemy,
        25 * selectedFrame, 0, 25, 25,
        trunc(dosuZone.x), trunc(dosuZone.y), trunc(dosuZone.width), trunc(dosuZone.height));

      PrintCentred('WASD - Move', 120);
      PrintCentred('Arrow keys - Resize', 130);
    end;

    DemoStateFlip: begin
      SprFlipped(texSlimeGirl, trunc(dosuZone.x), trunc(dosuZone.y), spriteFlip);
      PrintCentred('WASD - Move', 120);
      PrintCentred('Arrow keys - Flip', 130);
    end;

    DemoStateRotation: begin
      SprRotate(texSlimeGirl, trunc(dosuZone.x), trunc(dosuZone.y), spriteRotation);
      PrintCentred('WASD - Move', 120);
      PrintCentred('Left / right - Rotate', 130);
    end

    else begin
      if (trunc(gameTime * 4) and 1) > 0 then
        Spr(texDosuEXE[1], trunc(dosuZone.x), trunc(dosuZone.y))
      else
        Spr(texDosuEXE[0], trunc(dosuZone.x), trunc(dosuZone.y));

      PrintCentred('(Not implemented)', 130);
    end
  end;

  if showDemoList then begin
    PrintDefault('TAB - Hide the list of demos', 8, vgaHeight - 28);
    PrintDefault('Page up / down - Choose between demos', 8, vgaHeight - 18);
  end else
    PrintDefault('TAB - Show the list of demos', 8, vgaHeight - 18);

  DrawMouse;
  DrawFPS;
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

