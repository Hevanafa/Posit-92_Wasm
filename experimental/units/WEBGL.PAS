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
procedure glGetShaderInfoLog(shaderId: GLHandle); external 'env' name 'glGetShaderInfoLog';
{ High-level API for glGetShaderInfoLog }
function GetShaderInfoLog(shaderId: GLHandle): string;

function glCreateProgram: longword; external 'env' name 'glCreateProgram';
procedure glAttachShader(programId: GLHandle; shader: longword); external 'env' name 'glAttachShader';
procedure glLinkProgram(programId: GLHandle); external 'env' name 'glLinkProgram';
procedure glUseProgram(programId: GLHandle); external 'env' name 'glUseProgram';

function glGetProgramParameter(programId: GLHandle; param: GLenum): longint; external 'env' name 'glGetProgramParameter';
procedure glGetProgramInfoLog(programId: longword); external 'env' name 'glGetProgramInfoLog';
{ High-level API for glGetProgramInfoLog }
function GetProgramInfoLog(programId: longword): string;

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

uses Conv, Logger, InteropBuf, Panic, VGA;

const
  { Requires the `shaders` folder to be included
    in the Project settings > Paths }
  vertexSrc: string = {$I vertex.glsl.inc};
  fragSrc: string = {$I frag.glsl.inc};

var
  softwareTexture: GLHandle;
  vertexShader, fragShader: GLHandle;
  defaultProgram: GLHandle;

function GetShaderInfoLog(shaderId: GLHandle): string;
begin
  glGetShaderInfoLog(shaderId);
  GetShaderInfoLog := ReadInteropString
end;

function GetProgramInfoLog(programId: GLHandle): string;
begin
  glGetProgramInfoLog(programId);
  GetProgramInfoLog := ReadInteropString
end;

procedure SetupWebGLViewport;
begin
  glViewport(0, 0, vgaWidth, vgaHeight);
  softwareTexture := glCreateTexture;
  glBindTexture(GL_TEXTURE_2D, softwareTexture);

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

  { writelog('vertex shader id: ' + i32str(vertexShader)); }

  if glGetShaderParameter(vertexShader, GL_COMPILE_STATUS) = 0 then
    PanicHalt('Vertex shader error: ' + GetShaderInfoLog(vertexShader))
  else
    writelog('Vertex shader has been compiled');

  { Fragment shader - samples the texture }
  fragShader := glCreateShader(GL_FRAGMENT_SHADER);
  glShaderSource(fragShader, pchar(fragSrc));
  glCompileShader(fragShader);

  if glGetShaderParameter(fragShader, GL_COMPILE_STATUS) = 0 then
    PanicHalt('Fragment shader error: ' + GetShaderInfoLog(fragShader))
  else
    writeLog('Fragment shader has been compiled');

  { Link the vertex & fragment shaders }
  defaultProgram := glCreateProgram;
  glAttachShader(defaultProgram, vertexShader);
  glAttachShader(defaultProgram, fragShader);
  glLinkProgram(defaultProgram);

  if glGetProgramParameter(defaultProgram, GL_LINK_STATUS) = 0 then
    PanicHalt('Program link error: ' + GetProgramInfoLog(defaultProgram));

  glUseProgram(defaultProgram);

  texLoc := glGetUniformLocation(defaultProgram, 'u_tex');
  glUniform1i(texLoc, 0);

  posBuffer := glCreateBuffer;
  glBindBuffer(GL_ARRAY_BUFFER, posBuffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), @vertices, GL_STATIC_DRAW);

  posLoc := glGetAttribLocation(defaultProgram, 'a_pos');
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
  glBindTexture(GL_TEXTURE_2D, softwareTexture);
  glTexImage2D(
    GL_TEXTURE_2D, 0, GL_RGBA,
    320, 200, 0,
    GL_RGBA, GL_UNSIGNED_BYTE,
    getSurfacePtr);

  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)
end;

end.
