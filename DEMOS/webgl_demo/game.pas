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

  textureId: longword;  { Used by WebGL }

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

  glViewport(0, 0, 320, 200);
  textureId := glCreateTexture;
  glBindTexture(GL_TEXTURE_2D, textureId);

  { Enable nearest neighbour filter }
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
end;

procedure afterInit;
begin
  setupWebGLShaders;

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

  { Upload pixel data to the GPU }
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, textureId);
  glTexImage2D(
    GL_TEXTURE_2D, 0, GL_RGBA,
    320, 200, 0,
    GL_RGBA, GL_UNSIGNED_BYTE,
    getSurfacePtr);

  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)
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

  { Upload pixel data to the GPU }
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, textureId);
  glTexImage2D(
    GL_TEXTURE_2D, 0, GL_RGBA,
    320, 200, 0,
    GL_RGBA, GL_UNSIGNED_BYTE,
    getSurfacePtr);

  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)
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

