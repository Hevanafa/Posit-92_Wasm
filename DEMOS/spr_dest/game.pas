library Game;

{$Mode ObjFPC}

uses
  Keyboard, Mouse,
  ImgRef, ImgRefFast, Logger,
  Shapes, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  SC_W = $11;
  SC_A = $1E;
  SC_S = $1F;
  SC_D = $20;

  Velocity = 100; { pixels per second }

  CornflowerBlue = $FF6495ED;
  DarkBlue = $FF0000AA;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  imgTest: longint;
  img100Sprites: longint;
  layerZone: TRect;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure setRandomSeed(const seed: longint); public name 'setRandomSeed';
begin
  RandSeed := seed
  { randomize }
end;


procedure init;
begin
  initBuffer;
  initDeltaTime;
end;

procedure afterInit;
var
  a: word;
begin
  { Initialise game state here }
  hideCursor;

  writeLog('getTimer');
  writeLogI32(trunc(getTimer));
  setRandomSeed(trunc(getTimer));

  {
  imgTest := newImage(32, 32); 
  sprClear(imgTest, CornflowerBlue);
  sprToDest(imgDosuEXE[0], imgTest, 0, 0);
  }

  img100Sprites := newImage(vgaWidth, vgaHeight);
  for a:=1 to 100 do
    sprToDest(imgDosuEXE[0], img100Sprites, random(vgaWidth) - 20, random(vgaHeight) - 20);
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

  if isKeyDown(SC_W) then layerZone.y := layerZone.y - Velocity * dt;
  if isKeyDown(SC_S) then layerZone.y := layerZone.y + Velocity * dt;

  if isKeyDown(SC_A) then layerZone.x := layerZone.x - Velocity * dt;
  if isKeyDown(SC_D) then layerZone.x := layerZone.x + Velocity * dt;

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls(DarkBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  { spr(imgTest, 10, 10); }
  spr(img100Sprites, trunc(layerZone.x), trunc(layerZone.y));

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

