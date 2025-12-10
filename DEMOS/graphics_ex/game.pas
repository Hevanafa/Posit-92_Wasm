library Game;

{$Mode ObjFPC}

uses
  Conv, Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Graphics, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;

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

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
  { startTick, endTick: double; }
  { a: word; }
begin
  cls($FF6495ED);

  { startTick := getTimer; }

  {
  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);
  }

  circ(50, 50, 10, $80FF5555);
  circfill(80, 50, 10, $80FFAA55);

  rect(110, 50, 130, 70, $80FFFF55);
  rectfill(140, 50, 160, 70, $8055FF55);

  ellipse(50, 80, 20, 10, $805555FF);
  ellipsefill(80, 80, 20, 10, $8055AAFF);

  { endTick := getTimer; }
  { printDefault('10000 vline calls done in ' + f32str(endTick - startTick) + ' s', 10, 10); }

  drawMouse;
  vgaFlush
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

