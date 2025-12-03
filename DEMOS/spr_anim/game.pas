library Game;

{$Mode TP}

uses
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  SprAnim, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;

  hourglassFrameIdx: integer;
  hourglassStartTick: double;
  sprHourglass: TSpriteAnim;

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

  initSpriteAnim(sprHourglass, imgHourglass, 15, 32, 32, 0.2);
  sprHourglass.looping := false;
  rewindSpriteAnim(hourglassStartTick, getTimer, hourglassFrameIdx);
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

  updateSpriteAnim(sprHourglass, getTimer, hourglassStartTick, hourglassFrameIdx);

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

  spr(imgAppStartingCursor, 10, 10);
  { spr(imgHourglass, 10, 60); }
  drawSpriteAnim(sprHourglass, hourglassFrameIdx, 188, 80);

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

