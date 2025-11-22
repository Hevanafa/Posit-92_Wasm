library Game;

{$Mode ObjFPC}

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

var
  lastEsc: boolean;

  { Init your game state here }
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

  dosuZone.x := 148;
  dosuZone.y := 88;
  dosuZone.width := 24;
  dosuZone.height := 24;
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

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  with dosuZone do
    if (trunc(gameTime * 4) and 1) > 0 then
      sprStretch(imgDosuEXE[1], trunc(x), trunc(y), trunc(width), trunc(height))
    else
      sprStretch(imgDosuEXE[0], trunc(x), trunc(y), trunc(width), trunc(height));

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

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

