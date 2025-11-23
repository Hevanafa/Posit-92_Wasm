library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, Keyboard, Logger, Mouse,
  Panic, Shapes, Sounds, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

type
  TParticle = record
    active: boolean;
    zone: TRect;
    imgHandle: longint;
  end;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  particles: array[0..49] of longint;

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

procedure spawnParticle(const cx, cy: integer);
var
  a, idx: integer;
begin
  idx := -1;

  for a:=0 to high(particles) do
    if not particles[a].active then begin
      idx := a;
      break
    end;

  if idx < 0 then exit;

  particles[idx].active := true;
  
  particles[idx].zone := newRect(cx - 3, cy - 3, 7, 7);
  particles[idx].zone.vx := random - 0.5;
  particles[idx].zone.vy := -random;

  particles[idx].imgHandle := imgParticle;
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

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  spr(imgParticle, 10, 10);

  s := 'Hello world!';
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

