library Game;

{$Mode ObjFPC}
{$H-}

uses
  Keyboard, Mouse,
  ImgRef, ImgRefFast, Logger,
  Timing, VGA, WebGL,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  drawOnce: boolean;

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

  setupWebGLViewport;
  setupWebGLShaders;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;
  drawOnce := false;
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

{ Draw in WebGL context }
{ Test code }
procedure testDraw;
var
  a: integer;
begin
  for a:=0 to bufferSize - 1 do
    getSurfacePtr^[a] := $FF;

  if not drawOnce then begin
    writeLogI32(getSurfacePtr^[0]);
    writeLogI32(getSurfacePtr^[1]);
    writeLogI32(getSurfacePtr^[2]);
    writeLogI32(getSurfacePtr^[3]);
    drawOnce := true
  end;

  glClearColor(1.0, 0.4, 0.4, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);

  flushWebGL
end;


{ Draw in WebGL context }
procedure draw;
var
  s: string;
  w: word;
begin
{
  testDraw; exit;
}

  { CPU rendering code }
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := 'Hello from Posit-92 + WebAssembly + WebGL!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
  flushWebGL
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

