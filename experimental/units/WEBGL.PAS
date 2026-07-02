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

type
  GLHandle = longword;
  GLenum = longint;

procedure glClearColor(r, g, b, a: single); external 'env' name 'glClearColor';
procedure glClear(mask: longword); external 'env' name 'glClear';
procedure glViewport(x, y, width, height: longint); external 'env' name 'glViewport';

function glCreateTexture: GLHandle; external 'env' name 'glCreateTexture';
procedure glBindTexture(target, textureId: GLHandle); external 'env' name 'glBindTexture';
procedure glTexParameteri(target, pname, param: longword); external 'env' name 'glTexParameteri';

procedure glTexImage2D(
  target, level, internalFormat,
  width, height, border,
  format, pixelType: longword;
  pixels: pointer
); external 'env' name 'glTexImage2D';

function glCreateShader(shaderType: longword): longword; external 'env' name 'glCreateShader';
procedure glShaderSource(shaderId: GLHandle; source: PChar); external 'env' name 'glShaderSource';
procedure glCompileShader(shaderId: GLHandle); external 'env' name 'glCompileShader';

function glGetShaderParameter(shaderId: GLHandle; param: GLenum): longint; external 'env' name 'glGetShaderParameter';
function glGetShaderInfoLog(shaderId: GLHandle): pchar; external 'env' name 'glGetShaderParameter';

function glCreateProgram: longword; external 'env' name 'glCreateProgram';
procedure glAttachShader(programId: GLHandle; shader: longword); external 'env' name 'glAttachShader';
procedure glLinkProgram(programId: GLHandle); external 'env' name 'glLinkProgram';
procedure glUseProgram(programId: GLHandle); external 'env' name 'glUseProgram';

function glGetProgramParameter(programId: GLHandle; param: GLenum): longint; external 'env' name 'glGetProgramParameter';
function glGetProgramInfoLog(programId: longword): pchar; external 'env' name 'glGetProgramInfoLog';

function glCreateBuffer: longword; external 'env' name 'glCreateBuffer';
procedure glBindBuffer(target: longword; bufferId: GLHandle); external 'env' name 'glBindBuffer';
procedure glBufferData(target: longword; size: longint; data: pointer; usage: longword); external 'env' name 'glBufferData';
function glGetAttribLocation(programId: longword; name: PChar): longint; external 'env' name 'glGetAttribLocation';

procedure glEnableVertexAttribArray(idx: longword); external 'env' name 'glEnableVertexAttribArray';
procedure glVertexAttribPointer(idx, size, attrType: longword; normalized: boolean; stride, offset: longint); external 'env' name 'glVertexAttribPointer';
procedure glDrawArrays(mode: longword; first, count: longint); external 'env' name 'glDrawArrays';

function glGetUniformLocation(programId: GLHandle; name: PChar): longint; external 'env' name 'glGetUniformLocation';
procedure glUniform1i(locationId: GLHandle; value: longint); external 'env' name 'glUniform1i';

procedure glActiveTexture(textureId: GLHandle); external 'env' name 'glActiveTexture';

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
  vgaTextureId: longword;
  vertexShaderId, fragShaderId: longword;
  defaultProgramId: longword;

procedure SetupWebGLViewport;
begin
  glViewport(0, 0, vgaWidth, vgaHeight);
  vgaTextureId := glCreateTexture;
  glBindTexture(GL_TEXTURE_2D, vgaTextureId);

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
  vertexShaderId := glCreateShader(GL_VERTEX_SHADER);
  glShaderSource(vertexShaderId, pchar(vertexSrc));
  glCompileShader(vertexShaderId);

  if glGetShaderParameter(vertexShaderId, GL_COMPILE_STATUS) = 0 then
    writelog('Vertex shader error: ' + glGetShaderInfoLog(vertexShaderId))
  else
    writelog('Vertex shader has been compiled');

  { Fragment shader - samples the texture }
  fragShaderId := glCreateShader(GL_FRAGMENT_SHADER);
  glShaderSource(fragShaderId, pchar(fragSrc));
  glCompileShader(fragShaderId);

  writeLog('Fragment shader has been compiled');

  { Link the vertex & fragment shaders }
  defaultProgramId := glCreateProgram;
  glAttachShader(defaultProgramId, vertexShaderId);
  glAttachShader(defaultProgramId, fragShaderId);
  glLinkProgram(defaultProgramId);

  if glGetProgramParameter(defaultProgramId, GL_LINK_STATUS) = 0 then
    writelog('Program link error: ' + glGetProgramInfoLog(defaultProgramId));

  glUseProgram(defaultProgramId);

  texLoc := glGetUniformLocation(defaultProgramId, 'u_tex');
  glUniform1i(texLoc, 0);

  posBuffer := glCreateBuffer;
  glBindBuffer(GL_ARRAY_BUFFER, posBuffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), @vertices, GL_STATIC_DRAW);

  posLoc := glGetAttribLocation(defaultProgramId, 'a_pos');
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
  glBindTexture(GL_TEXTURE_2D, vgaTextureId);
  glTexImage2D(
    GL_TEXTURE_2D, 0, GL_RGBA,
    320, 200, 0,
    GL_RGBA, GL_UNSIGNED_BYTE,
    getSurfacePtr);

  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)
end;

end.
