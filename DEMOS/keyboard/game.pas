library Game;

{$Mode ObjFPC}

uses
  BMFont, Conv, FPS, Graphics,
  Keyboard, Logger, Mouse,
  Panic, SprFast, Shapes, Timing,
  VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  SC_W = $11;
  SC_A = $1E;
  SC_S = $1F;
  SC_D = $20;

  MoveSpeed = 100;  { pixels per second }

  White = $FFFFFFFF;  { AARRGGBB }

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  playerZone: TRect;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';


procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
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

  playerZone := newRect(155, 95, 10, 10);
end;

procedure update;
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

  if isKeyDown(SC_W) then playerZone.y := playerZone.y - MoveSpeed * dt;
  if isKeyDown(SC_S) then playerZone.y := playerZone.y + MoveSpeed * dt;

  if isKeyDown(SC_A) then playerZone.x := playerZone.x - MoveSpeed * dt;
  if isKeyDown(SC_D) then playerZone.x := playerZone.x + MoveSpeed * dt;

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  drawZone(playerZone, White);

  s := 'WASD - Move';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

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

