library Game;

{$Mode TP}

uses
  Keyboard, Mouse,
  ImgRef, ImgRefFast, SprEffects,
  Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  Grey = $FF555555;

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
  offsetY: integer;
begin
  cls($FF6495ED);

  offsetY := trunc(sin(getTimer * 3.0) * 10);

  if (trunc(gameTime * 4) and 1) > 0 then
    sprShadow(imgDosuEXE[1], 148, 88, 10, offsetY, grey)
  else
    sprShadow(imgDosuEXE[0], 148, 88, 10, offsetY, grey);

  s := 'Hello world!';
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

