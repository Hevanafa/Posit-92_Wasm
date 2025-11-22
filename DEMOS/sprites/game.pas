library Game;

{$Mode TP}
{$B-}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, Keyboard, Logger, Mouse,
  Panic, Shapes, Sounds, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  { For movement }
  SC_W = $11;
  SC_A = $1E;
  SC_S = $1F;
  SC_D = $20;

  { For scaling }
  SC_UP = $48;
  SC_LEFT = $4B;
  SC_RIGHT = $4D;
  SC_DOWN = $50;

  Black = $FF000000;
  White = $FFFFFFFF;
  Red = $FFFF5555;

  { DemoStates enum }
  DemoStateFullSprite = 1;
  DemoStateRegion = 2;
  DemoStateBlend = 3;
  DemoStateScaling = 4;
  DemoStateRegionScaling = 5;
  DemoStateFlip = 6;
  DemoStateRotation = 7;

var
  lastEsc: boolean;

  { Init your game state here }
  actualDemoState: integer;
  gameTime: double;
  dosuZone: TRect;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

{ demoState: use DemoStates }
procedure changeState(const newState: integer);
begin
  actualDemoState := newState;

  gameTime := 0.0;

  dosuZone.x := 148;
  dosuZone.y := 88;
  dosuZone.width := 24;
  dosuZone.height := 24;
end;


procedure init;
begin
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;

  changeState(DemoStateScaling);
end;

procedure printCentred(const text: string; const y: integer);
var
  w: word;
begin
  w := measureDefault(text);
  printDefault(text, (vgaWidth - w) div 2, y);
end;

function getDemoStateName(const state: integer): string;
var
  result: string;
begin
  case state of
    DemoStateFullSprite:
      result := 'Full sprite';
    DemoStateRegion:
      result := 'Sprite region';
    DemoStateBlend:
      result := 'Alpha blending';
    DemoStateScaling:
      result := 'Sprite scaling';
    DemoStateRegionScaling:
      result := 'Region scaling';
    DemoStateFlip:
      result := 'Sprite flipping';
    DemoStateRotation:
      result := 'Sprite rotation';
  end;

  getDemoStateName := result
end;

procedure drawDemoList;
const
  top = 10;
  left = 10;
var
  a: word;
  lineHeight: word;
  height: word;
begin
  lineHeight := _defaultFont.lineHeight + 2;
  height := lineHeight * DemoStateRotation;

  rectfill(left, top, 100, top + height, Black);

  rectfill(
    left, top + lineHeight * (actualDemoState - 1),
    100, top + lineHeight * actualDemoState, Red);

  for a := 1 to DemoStateRotation do
    printDefault(
      getDemoStateName(a),
      left + 2, top + 2 + lineHeight * (a - 1));

  rect(left, top, 100, top + height, White);
end;


procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  if isKeyDown(SC_W) then dosuZone.y := dosuZone.y - 1;
  if isKeyDown(SC_S) then dosuZone.y := dosuZone.y + 1;

  if isKeyDown(SC_A) then dosuZone.x := dosuZone.x - 1;
  if isKeyDown(SC_D) then dosuZone.x := dosuZone.x + 1;

  if isKeyDown(SC_UP) and (dosuZone.height > 1.0) then dosuZone.height := dosuZone.height - 1;
  if isKeyDown(SC_DOWN) then dosuZone.height := dosuZone.height + 1;

  if isKeyDown(SC_RIGHT) then dosuZone.width := dosuZone.width + 1;
  if isKeyDown(SC_LEFT) and (dosuZone.width > 1.0) then dosuZone.width := dosuZone.width - 1;

  gameTime := gameTime + dt
end;

procedure draw;
begin
  cls($FF6495ED);

  { writeLogF32(gameTime * 4); }

  {
  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);
  }

  drawDemoList;

  
  with dosuZone do
    if (trunc(gameTime * 4) and 1) > 0 then
      sprStretch(imgDosuEXE[1], trunc(x), trunc(y), trunc(width), trunc(height))
    else
      sprStretch(imgDosuEXE[0], trunc(x), trunc(y), trunc(width), trunc(height));

  printCentred('WASD - Move', 120);
  printCentred('Arrow keys - Resize', 130);

  drawMouse;
  drawFPS;

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

