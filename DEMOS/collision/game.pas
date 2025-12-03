library Game;

{$Mode ObjFPC}

uses
  Conv, Graphics, Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Shapes, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  SC_W = $11;
  SC_A = $1E;
  SC_S = $1F;
  SC_D = $20;

  MoveSpeed = 100;  { pixels per second }

  Grey = $FFAAAAAA;
  White = $FFFFFFFF;  { AARRGGBB }
  Green = $FF55FF55;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  mapBounds: TRect;

  playerZone, npcZone: TRect;
  playerCircleZone, npcCircleZone: TCircle;


{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;


procedure init;
begin
  initBuffer;
  initDeltaTime;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;

  mapBounds := newRect(20, 20, 280, 160);

  playerZone := newRect(155, 95, 24, 24);
  npcZone := newRect(180, 55, 24, 24);

  playerCircleZone.cx := 155;
  playerCircleZone.cy := 95;
  playerCircleZone.radius := 30;

  npcCircleZone.cx := getZoneCX(npcZone);
  npcCircleZone.cy := getZoneCY(npcZone);
  npcCircleZone.radius := 30;
end;

procedure update;
begin
  updateDeltaTime;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then signalDone;
  end;

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
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  { Circle to circle intersection }
  {
  drawCircleZone(
    playerCircleZone,
    u32Iif(circleIntersects(playerCircleZone, npcCircleZone),
      green, grey));

  drawCircleZone(npcCircleZone, white);
  }

  { Rectangle intersection}
  {
  drawZone(
    playerZone,
    u32Iif(rectIntersects(playerZone, npcZone),
      white, grey));

  drawZone(
    npcZone,
    u32Iif(rectIntersects(playerZone, npcZone),
      white, grey));
  }

  { Circle to rect intersection }
  drawCircleZone(
    playerCircleZone,
    u32Iif(circleRectIntersects(playerCircleZone, npcZone),
      green, grey));

  drawZone(npcZone, white);

  spr(imgDosuEXE[1], trunc(npcZone.x), trunc(npcZone.y));

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], trunc(playerZone.x), trunc(playerZone.y))
  else
    spr(imgDosuEXE[0], trunc(playerZone.x), trunc(playerZone.y));

  s := 'WASD - Move';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
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

