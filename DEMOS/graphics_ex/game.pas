library Game;

{$Mode ObjFPC}

uses
  Conv, Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Graphics, Shapes, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  testPoints: array [0..3] of TPoint;

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

  testPoints[0].x := 100; testPoints[0].y := 50;
  testPoints[1].x := 150; testPoints[1].y := 100;
  testPoints[2].x := 100; testPoints[2].y := 150;
  testPoints[3].x := 50;  testPoints[3].y := 100;
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
  startTick, endTick: double;
  { a: word; }
  a: longword;
begin
  cls($FF6495ED);

  { Benchmarking segment }
  {
  startTick := getTimer;

  for a:=1 to 1000000 do
    unsafePset(random(vgaWidth), random(vgaHeight), $FFFF5555);

  endTick := getTimer;
  printDefault('1M unsafePset calls done in ' + f32str(endTick - startTick) + ' s', 10, 10);
  vgaFlush;

  exit;
  }

  {
  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);
  }

  circ(50, 50, 10, $80FF5555);
  circfill(80, 50, 10, $80FFAA55);

  { rect(110, 50, 130, 70, $80FFFF55); }
  rectRound(110, 50, 130, 70, 5, $80FFFF55);
  rectfill(140, 50, 160, 70, $8055FF55);

  ellipse(50, 80, 20, 10, $805555FF);
  ellipsefill(80, 80, 20, 10, $8055AAFF);

  tri(50, 110, 70, 120, 40, 130, $80AA55AA);
  trifill(80, 110, 100, 120, 70, 130, $80FF55FF);

  polygonPtr(@testPoints[0], length(testPoints), $80FF5555);

  arc(160, 100, 50, 0, pi, $FFFF5555);
  pie(160, 100, 50, pi / 4, 3 * pi / 4, $FF55FF55);

  lineThick(50, 50, 200, 150, 15, $FFFF5555);

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

