library Game;

{$Mode ObjFPC}

uses
  Keyboard, Mouse,
  { ImgRef, ImgRefFast, }
  Timing, VGA, WebGL,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  textureId: longword;  { Used by WebGL }

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

{
procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;
}

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

{ Draw in WebGL context }
procedure draw;
begin
  { glClearColor(0.2, 0.4, 0.8, 1.0); }
  glClearColor(0.39, 0.58, 0.92, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);

  { Upload pixel data to the GPU }
  glBindTexture(GL_TEXTURE_2D, textureId);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 320, 200, 0, GL_RGBA, GL_UNSIGNED_BYTE, getSurfacePtr)
end;

{ Draw in canvas context }
{
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

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
  flush
end;
}

exports
  { Main game procedures }
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

