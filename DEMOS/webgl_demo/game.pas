library Game;

{$Mode ObjFPC}
{$ModeSwitch MultiLineStrings}
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
end;

procedure afterInit;
var
  vertShader, fragShader, prog: longword;
  texLoc: longint;
  posBuffer: longword;
  posLoc: longint;
  vertices: array[0..7] of single = (
    -1, -1, 1, -1,
    -1, 1, 1, 1);
begin
  { Vertex shader - positions a fullscreen quad }
  vertShader := glCreateShader(GL_VERTEX_SHADER);

  glShaderSource(vertShader,`
attribute vec2 pos;
varying vec2 uv;
void main() {
  uv = pos * 0.5 + 0.5;
  gl_Position = vec4(pos, 0.0, 1.0);
}
  `);

  glCompileShader(vertShader);

  { Fragment shader - samples the texture }
  fragShader := glCreateShader(GL_FRAGMENT_SHADER);

  glShaderSource(fragShader, `
precision mediump float;
varying vec2 uv;
uniform sampler2D tex;
void main() {
  gl_FragColor = texture2D(tex, vec2(uv.x, 1.0 - uv.y));
}
  `);

  glCompileShader(fragShader);
  writeLog('Vertex shader has been compiled');

  { Link the vertex & fragment shaders }
  prog := glCreateProgram;
  glAttachShader(prog, vertShader);
  glAttachShader(prog, fragShader);
  glLinkProgram(prog);
  glUseProgram(prog);

  texLoc := glGetUniformLocation(prog, 'tex');
  writeLog('texLoc');
  writeLogI32(texLoc);

  glUniform1i(texLoc, 0);

  posBuffer := glCreateBuffer;
  glBindBuffer(GL_ARRAY_BUFFER, posBuffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), @vertices, GL_STATIC_DRAW);

  posLoc := glGetAttribLocation(prog, 'pos');
  glEnableVertexAttribArray(posLoc);
  glVertexAttribPointer(posLoc, 2, GL_FLOAT, false, 0, 0);

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
procedure draw;
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

  glActiveTexture(GL_TEXTURE0);

  { Upload pixel data to the GPU }
  glBindTexture(GL_TEXTURE_2D, textureId);
  glTexImage2D(
    GL_TEXTURE_2D, 0, GL_RGBA,
    320, 200, 0,
    GL_RGBA, GL_UNSIGNED_BYTE,
    getSurfacePtr);

  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)
end;

{ Draw in WebGL context }
{
procedure draw;
var
  s: string;
  w: word;
begin
  glClearColor(1.0, 0.4, 0.4, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
}
  { CPU rendering code }
{
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
}

  { Upload pixel data to the GPU }
{
  glBindTexture(GL_TEXTURE_2D, textureId);
  glTexImage2D(
    GL_TEXTURE_2D, 0, GL_RGBA,
    320, 200, 0,
    GL_RGBA, GL_UNSIGNED_BYTE,
    getSurfacePtr);

  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
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

