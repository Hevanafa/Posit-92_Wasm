{
  WebGL unit - Part of Posit-92 game engine
  Hevanafa

  A thin 1:1 wrapper around WebGL
}

unit WebGL;

{$Mode ObjFPC}
{$H+}{$J-}
{$ModeSwitch MultiLineStrings}

interface

const
  GL_COLOR_BUFFER_BIT = $00004000;
  GL_DEPTH_BUFFER_BIT = $00000100;
  GL_TRIANGLES = $0004;

  GL_TEXTURE_2D = $0DE1;
  GL_TEXTURE_MIN_FILTER = $2801;
  GL_TEXTURE_MAG_FILTER = $2800;
  GL_NEAREST = $2600;

  GL_RGBA = $1908;
  GL_UNSIGNED_BYTE = $1401;

  GL_VERTEX_SHADER = $8B31;
  GL_FRAGMENT_SHADER = $8B30;
  GL_COMPILE_STATUS = $8B81;
  GL_LINK_STATUS = $8B82;

  GL_ARRAY_BUFFER = $8892;
  GL_STATIC_DRAW = $88E4;
  GL_FLOAT = $1406;
  GL_TRIANGLE_STRIP = $0005;

  GL_TEXTURE0 = $84C0;

  GL_TEXTURE_WRAP_S = $2802;
  GL_TEXTURE_WRAP_T = $2803;
  GL_CLAMP_TO_EDGE = $812F;

procedure glClearColor(const r, g, b, a: single); external 'env' name 'glClearColor';
procedure glClear(const mask: longword); external 'env' name 'glClear';
procedure glViewport(const x, y, width, height: longint); external 'env' name 'glViewport';

function glCreateTexture: longword; external 'env' name 'glCreateTexture';
procedure glBindTexture(const target, texture: longword); external 'env' name 'glBindTexture';
procedure glTexParameteri(const target, pname, param: longword); external 'env' name 'glTexParameteri';

procedure glTexImage2D(
  const target, level, internalFormat,
    width, height, border,
    format, pixelType: longword;
  const pixels: pointer); external 'env' name 'glTexImage2D';

function glCreateShader(const shaderType: longword): longword; external 'env' name 'glCreateShader';
procedure glShaderSource(const shaderId: longword; const source: PChar); external 'env' name 'glShaderSource';
procedure glCompileShader(const shaderId: longword); external 'env' name 'glCompileShader';

function glGetShaderParameter(const shaderId, pname: longword): longint; external 'env' name 'glGetShaderParameter';

function glCreateProgram: longword; external 'env' name 'glCreateProgram';
procedure glAttachShader(const programId, shader: longword); external 'env' name 'glAttachShader';
procedure glLinkProgram(const programId: longword); external 'env' name 'glLinkProgram';
procedure glUseProgram(const programId: longword); external 'env' name 'glUseProgram';

function glCreateBuffer: longword; external 'env' name 'glCreateBuffer';
procedure glBindBuffer(const target, bufferId: longword); external 'env' name 'glBindBuffer';
procedure glBufferData(const target: longword; const size: longint; const data: pointer; const usage: longword); external 'env' name 'glBufferData';
function glGetAttribLocation(const programId: longword; const name: PChar): longint; external 'env' name 'glGetAttribLocation';

procedure glEnableVertexAttribArray(const idx: longword); external 'env' name 'glEnableVertexAttribArray';
procedure glVertexAttribPointer(const idx, size, attrType: longword; const normalized: boolean; const stride, offset: longint); external 'env' name 'glVertexAttribPointer';
procedure glDrawArrays(const mode: longword; const first, count: longint); external 'env' name 'glDrawArrays';

function glGetUniformLocation(const programId: longword; const name: PChar): longint; external 'env' name 'glGetUniformLocation';
procedure glUniform1i(const locationId, value: longint); external 'env' name 'glUniform1i';

procedure glActiveTexture(const textureId: longword); external 'env' name 'glActiveTexture';

procedure SetupWebGLViewport;
procedure SetupWebGLShaders;
procedure WebGLPresent;


implementation

uses Logger, VGA;

const
  { Requires the `shaders` folder to be included
    in the Project settings > Paths }
  vertexSrc: string = {$I vertex.glsl.inc};
  fragSrc: string = {$I frag.glsl.inc};

var
  textureId: longword;  { Used by WebGL }
  vertexShader, fragShader, prog: longword;

procedure SetupWebGLViewport;
begin
  glViewport(0, 0, vgaWidth, vgaHeight);
  textureId := glCreateTexture;
  glBindTexture(GL_TEXTURE_2D, textureId);

  { Enable nearest neighbour filter }
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
end;

procedure SetupWebGLShaders;
const
  vertices: array[0..7] of single = (
    -1, -1,
    1, -1,
    -1, 1,
    1, 1
  );

var
  texLoc: longint;
  posBuffer: longword;
  posLoc: longint;

begin
  { Vertex shader - positions a fullscreen quad }
  vertexShader := glCreateShader(GL_VERTEX_SHADER);
  glShaderSource(vertexShader, pchar(vertexSrc));
  glCompileShader(vertexShader);

  { if glgetshaderparameter(vertexShader, GL_COMPILE_STATUS) = 0 then
    writelog('Vertex shader error: ' + glgetshaderinfolog(vertexShader))
  else }
  writelog('Vertex shader has been compiled');

  { Fragment shader - samples the texture }
  fragShader := glCreateShader(GL_FRAGMENT_SHADER);
  glShaderSource(fragShader, pchar(fragSrc));
  glCompileShader(fragShader);

  writeLog('Fragment shader has been compiled');

  { Link the vertex & fragment shaders }
  prog := glCreateProgram;
  glAttachShader(prog, vertexShader);
  glAttachShader(prog, fragShader);
  glLinkProgram(prog);

  { if glgetprogramparameter(prog, GL_LINK_STATUS) = 0 then
    writelog('Program link error: ' + glgetprograminfolog(prog)); }

  glUseProgram(prog);

  texLoc := glGetUniformLocation(prog, 'u_tex');
  glUniform1i(texLoc, 0);

  posBuffer := glCreateBuffer;
  glBindBuffer(GL_ARRAY_BUFFER, posBuffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), @vertices, GL_STATIC_DRAW);

  posLoc := glGetAttribLocation(prog, 'a_pos');
  glEnableVertexAttribArray(posLoc);
  glVertexAttribPointer(posLoc, 2, GL_FLOAT, false, 0, 0);
end;

{ Upload pixel data to the GPU }
procedure WebGLPresent;
begin
{
  glClearColor(1.0, 0.4, 0.4, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
}

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, textureId);
  glTexImage2D(
    GL_TEXTURE_2D, 0, GL_RGBA,
    320, 200, 0,
    GL_RGBA, GL_UNSIGNED_BYTE,
    getSurfacePtr);

  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)
end;

end.
