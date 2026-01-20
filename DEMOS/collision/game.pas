library Game;

{$Mode ObjFPC}
{$H-}

uses
  Conv, Fullscreen, Graphics, IIF,
  Loading, Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Shapes, Timing, WasmMemMgr, VGA,
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
  SC_TAB = $0F;

  SC_1 = $02;
  SC_2 = $03;
  SC_3 = $04;

  SC_W = $11;
  SC_A = $1E;
  SC_S = $1F;
  SC_D = $20;

  MoveSpeed = 100;  { pixels per second }

  Grey = $FFAAAAAA;
  White = $FFFFFFFF;  { AARRGGBB }
  Green = $FF55FF55;
  Yellow = $FFFFFF55;

  DemoModeRect = 1;
  DemoModeCircle = 2;
  DemoModeCircleRect = 3;

var
  lastEsc, lastTab: boolean;

  { Game state variables }
  actualGameState: TGameStates;
  gameTime: double;

  actualDemoMode: integer;

  mapBounds: TZone;

  playerZone, npcZone: TZone;
  playerCircleZone, npcCircleZone: TCircle;


{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure loadAssets; external 'env' name 'loadAssets';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

function getDemoModeName(const mode: integer): string;
begin
  case mode of
    DemoModeRect: result := 'Rect vs Rect';
    DemoModeCircle: result := 'Circle vs Circle';
    DemoModeCircleRect: result := 'Circle vs Rect';
    else result := 'Unknown mode: ' + i32str(mode)
  end;

  getDemoModeName := result
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

  actualDemoMode := DemoModeRect;

  mapBounds := newZone(20, 20, 280, 160);

  playerZone := newZone(155, 95, 24, 24);
  npcZone := newZone(180, 55, 24, 24);

  playerCircleZone.cx := 155;
  playerCircleZone.cy := 95;
  playerCircleZone.radius := 30;

  npcCircleZone.cx := getZoneCX(npcZone);
  npcCircleZone.cy := getZoneCY(npcZone);
  npcCircleZone.radius := 30;
end;


procedure init;
begin
  initHeapMgr;
  initDeltaTime
end;

procedure afterInit;
begin
  beginPlayingState
end;

procedure update;
var
  tempZone: TZone;
  tempCircle: TCircle;
begin
  updateDeltaTime;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then signalDone;
  end;

  if lastTab <> isKeyDown(SC_TAB) then begin
    lastTab := isKeyDown(SC_TAB);

    if lastTab then begin
      tempZone := playerZone;
      playerZone := npcZone;
      npcZone := tempZone;

      tempCircle := playerCircleZone;
      playerCircleZone := npcCircleZone;
      npcCircleZone := tempCircle;
    end;
  end;

  if isKeyDown(SC_1) then actualDemoMode := DemoModeRect;
  if isKeyDown(SC_2) then actualDemoMode := DemoModeCircle;
  if isKeyDown(SC_3) then actualDemoMode := DemoModeCircleRect;

  if isKeyDown(SC_W) then playerZone.y := playerZone.y - MoveSpeed * dt;
  if isKeyDown(SC_S) then playerZone.y := playerZone.y + MoveSpeed * dt;

  if isKeyDown(SC_A) then playerZone.x := playerZone.x - MoveSpeed * dt;
  if isKeyDown(SC_D) then playerZone.x := playerZone.x + MoveSpeed * dt;

  if playerZone.x < mapBounds.x then playerZone.x := mapBounds.x;
  if playerZone.y < mapBounds.y then playerZone.y := mapBounds.y;

  if playerZone.x + playerZone.width >= mapBounds.x + mapBounds.width then
    playerZone.x := mapBounds.x + mapBounds.width - playerZone.width;
  if playerZone.y + playerZone.height >= mapBounds.y + mapBounds.height then
    playerZone.y := mapBounds.y + mapBounds.height - playerZone.height;

  playerCircleZone.cx := getZoneCX(playerZone);
  playerCircleZone.cy := getZoneCY(playerZone);

  gameTime := gameTime + dt
end;

procedure draw;
var
  mouseP: TPoint;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;

  cls($FF6495ED);

  mouseP.x := mouseX;
  mouseP.y := mouseY;

  { Rectangle intersection }
  case actualDemoMode of
    DemoModeRect: begin
      if pointInZone(mouseP, playerZone) then
        drawZone(playerZone, yellow)
      else
        drawZone(
          playerZone,
          u32Iif(zoneIntersects(playerZone, npcZone),
            green, white));

      drawZone(
        npcZone,
        u32Iif(zoneIntersects(playerZone, npcZone),
          white, grey));
    end;

    DemoModeCircle: begin
      if pointInCircle(mouseP, playerCircleZone) then
        drawCircleZone(playerCircleZone, yellow)
      else
        drawCircleZone(
          playerCircleZone,
          u32Iif(circleIntersects(playerCircleZone, npcCircleZone),
            green, white));

      drawCircleZone(npcCircleZone, grey);
    end;

    DemoModeCircleRect: begin
      if pointInCircle(mouseP, playerCircleZone) then
        drawCircleZone(playerCircleZone, yellow)
      else
        drawCircleZone(
          playerCircleZone,
          u32Iif(circleZoneIntersects(playerCircleZone, npcZone),
            green, white));

      drawZone(npcZone, grey);
    end;
  end;

  spr(imgDosuEXE[1], trunc(npcZone.x), trunc(npcZone.y));

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], trunc(playerZone.x), trunc(playerZone.y))
  else
    spr(imgDosuEXE[0], trunc(playerZone.x), trunc(playerZone.y));

  printDefault('Mode: ' + getDemoModeName(actualDemoMode), 10, 10);

  printDefault('WASD - Move', 8, 160);
  printDefault('TAB - Switch entity', 8, 170);
  printDefault('1, 2, 3 - Change mode', 8, 180);

  printDefault('Hover over an active entity', 128, 160);
  printDefault('to turn the zone yellow', 128, 170);

  drawMouse;
  vgaFlush
end;

exports
  beginLoadingState,
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.

