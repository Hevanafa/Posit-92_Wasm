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

  cursorFrameIdx: integer;
  cursorStartTick: double;
  sprAppStartingCursor: TSpriteAnim;

  cheetahFrameIdx: integer;
  cheetahStartTick: double;
  sprCheetah: TSpriteAnim;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawMouse;
begin
  { spr(imgCursor, mouseX, mouseY) }
  drawSpriteAnim(sprAppStartingCursor, cursorFrameIdx, mouseX, mouseY)
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
  { sprHourglass.looping := false; }
  rewindSpriteAnim(hourglassStartTick, getTimer, hourglassFrameIdx);

  initSpriteAnim(sprAppStartingCursor, imgAppStartingCursor, 10, 32, 32, 0.2);
  rewindSpriteAnim(cursorStartTick, getTimer, cursorFrameIdx);

  initSpriteAnim(sprCheetah, imgCheetah, 8, 133, 63, 0.05);
  rewindSpriteAnim(cheetahStartTick, getTimer, cheetahFrameIdx);
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
  updateSpriteAnim(sprAppStartingCursor, getTimer, cursorStartTick, cursorFrameIdx);

  updateSpriteAnim(sprCheetah, getTimer, cheetahStartTick, cheetahFrameIdx);

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

  { spr(imgAppStartingCursor, 10, 10); }
  { spr(imgHourglass, 10, 60); }

  drawSpriteAnim(sprCheetah, cheetahFrameIdx, 20, 20);

  drawSpriteAnim(sprHourglass, hourglassFrameIdx, 188, 80);

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

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

