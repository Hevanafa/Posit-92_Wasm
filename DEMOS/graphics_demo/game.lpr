library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Conversions, P92WasmHost, P92AssetRegistry,
  P92Loading,
  P92Keyboard, P92Mouse,
  P92Tex, P92TexDraw,
  P92Graphics, P92Timing, P92Geometry, P92VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Game state variables }
  gameTime: double;
  testPoints: array [0..3] of TPoint;

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure OnReady;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  gameTime := 0.0;
  
  testPoints[0].x := 100; testPoints[0].y := 50;
  testPoints[1].x := 150; testPoints[1].y := 100;
  testPoints[2].x := 100; testPoints[2].y := 150;
  testPoints[3].x := 50;  testPoints[3].y := 100;
end;

procedure Update;
begin
  { Your Update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then signalDone;
  end;

  gameTime := gameTime + deltatime
end;

procedure Draw;
var
  w: integer;
  s: string;
  startTick, endTick: double;
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

  Circ(50, 50, 10, $80FF5555);
  CircFill(80, 50, 10, $80FFAA55);

  { Rect(110, 50, 130, 70, $80FFFF55); }
  RectRound(110, 50, 130, 70, 5, $80FFFF55);
  RectFill(140, 50, 160, 70, $8055FF55);

  Ellipse(50, 80, 20, 10, $805555FF);
  Ellipsefill(80, 80, 20, 10, $8055AAFF);

  Tri(50, 110, 70, 120, 40, 130, $80AA55AA);
  TriFill(80, 110, 100, 120, 70, 130, $80FF55FF);

  PolygonPtr(@testPoints[0], length(testPoints), $80FF5555);

  Arc(160, 100, 50, 0, pi, $FFFF5555);
  Pie(160, 100, 50, pi / 4, 3 * pi / 4, $FF55FF55);

  LineThick(50, 50, 200, 150, 15, $FFFF5555);

  DrawMouse;

  VgaUpload;
  VgaPresent
end;

exports
  OnReady, Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

