library Game;

{$Mode ObjFPC}

uses
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  CornflowerBlue = $FF6495ED;
  DarkBlue = $FF0000AA;

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
begin
  startTick := getTimer;

  imgLayer := newImage(vgaWidth, vgaHeight);
  { sprClear(imgTest, CornflowerBlue); }
  for a:=0 to 100 do
    sprToDest(imgDosuEXE[0], imgLayer, random(vgaWidth), random(vgaHeight));

  endTick := getTimer;

  cls(DarkBlue);

{
  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);
}

  spr(imgLayer, 10, 10);

  printDefault('100 sprites rendered in ' + f32str(endTick - startTick) + ' seconds');

{
  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
}
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

