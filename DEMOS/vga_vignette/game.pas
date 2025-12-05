library Game;

{$Mode TP}

uses
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  PostProc, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  SC_LEFT = $4B;
  SC_RIGHT = $4D;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  vignetteStrength: double;

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

  vignetteStrength := 0.3;
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

  if isKeyDown(SC_LEFT) then
    vignetteStrength := vignetteStrength - dt / 2;
  
  if isKeyDown(SC_RIGHT) then
    vignetteStrength := vignetteStrength + dt / 2;

  vignetteStrength := clamp(vignetteStrength, 0.0, 1.0);

  gameTime := gameTime + dt
end;

procedure draw;
var
  s: string;
  w: word;
begin
  cls($FF6495ED);

  spr(imgArkRoad, 0, 0);

  applyFullVignette(vignetteStrength);

  printDefault('Left / right: Adjust strength', 10, vgaHeight - 20);

  s := 'Art by Kevin Hong';
  w := measureDefault(s);
  printDefault(s, vgaWidth - w - 10, vgaHeight - 20);

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

