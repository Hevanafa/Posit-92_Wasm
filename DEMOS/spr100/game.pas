library Game;

{$Mode TP}

uses
  BMFont, Conv, Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  CornflowerBlue = $FF6495ED;
  Black = $FF000000;
  DarkBlue = $FF0000AA;
  Green = $FF55FF55;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  imgLayer: longint;

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

  imgLayer := newImage(vgaWidth, vgaHeight);
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
  a: word;
  startTick, endTick: double;
begin
  startTick := getTimer;

  for a:=0 to 1000 do
    sprToDest(imgDosuEXE[0], imgLayer, random(vgaWidth) - 20, random(vgaHeight) - 20);

  endTick := getTimer;

  cls(DarkBlue);
  spr(imgLayer, 0, 0);

  printBMFontColour(
    '1000 sprites rendered in ' + f32str(endTick - startTick) + ' seconds',
    10, 10,
    defaultFont, defaultFontGlyphs,
    green);

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

