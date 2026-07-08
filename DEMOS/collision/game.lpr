{
  Collision demo
  Part of Posit-92 game engine
  Mixins: bmfont, sound
}

library Game;

{$Mode ObjFPC}
{$H-}

uses
  P92Core, P92Fonts, P92WasmHost, P92AssetRegistry,
  P92Conversions, P92Graphics, IIF,
  P92Keyboard, P92Mouse,
  P92Tex, P92TexDraw, P92Geometry,
  P92Timing, P92VGA,
  Assets;

const
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
  gameTime: double;

  actualDemoMode: integer;

  mapBounds: TZone;

  playerZone, npcZone: TZone;
  playerCircleZone, npcCircleZone: TCircle;


procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

function GetDemoModeName(const mode: integer): string;
begin
  case mode of
    DemoModeRect: result := 'Rect vs Rect';
    DemoModeCircle: result := 'Circle vs Circle';
    DemoModeCircleRect: result := 'Circle vs Rect';
    else result := 'Unknown mode: ' + i32str(mode)
  end;

  GetDemoModeName := result
end;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');

  imgDosuEXE[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuEXE[1] := RequestImage('assets/images/dosu_2.png');
end;

procedure OnReady;
begin
  hideCursor;

  { Initialise game state here }
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


procedure Update;
var
  tempZone: TZone;
  tempCircle: TCircle;
begin
  if lastEsc <> isKeyDown(SC_ESCAPE) then begin
    lastEsc := isKeyDown(SC_ESCAPE);
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

  if isKeyDown(SC_W) then playerZone.y := playerZone.y - MoveSpeed * DeltaTime;
  if isKeyDown(SC_S) then playerZone.y := playerZone.y + MoveSpeed * DeltaTime;

  if isKeyDown(SC_A) then playerZone.x := playerZone.x - MoveSpeed * DeltaTime;
  if isKeyDown(SC_D) then playerZone.x := playerZone.x + MoveSpeed * DeltaTime;

  if playerZone.x < mapBounds.x then playerZone.x := mapBounds.x;
  if playerZone.y < mapBounds.y then playerZone.y := mapBounds.y;

  if playerZone.x + playerZone.width >= mapBounds.x + mapBounds.width then
    playerZone.x := mapBounds.x + mapBounds.width - playerZone.width;
  if playerZone.y + playerZone.height >= mapBounds.y + mapBounds.height then
    playerZone.y := mapBounds.y + mapBounds.height - playerZone.height;

  playerCircleZone.cx := getZoneCX(playerZone);
  playerCircleZone.cy := getZoneCY(playerZone);

  gameTime := gameTime + DeltaTime
end;

procedure Draw;
var
  mouseP: TPoint;
begin
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

  printDefault('Mode: ' + GetDemoModeName(actualDemoMode), 10, 10);

  printDefault('WASD - Move', 8, 160);
  printDefault('TAB - Switch entity', 8, 170);
  printDefault('1, 2, 3 - Change mode', 8, 180);

  printDefault('Hover over an active entity', 128, 160);
  printDefault('to turn the zone yellow', 128, 170);

  DrawMouse
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

