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

procedure GLClearColor(r, g, b, a: single); external 'env' name 'GLClearColor';
procedure GLClear(mask: longword); external 'env' name 'GLClear';
procedure GLViewport(x, y, width, height: longint); external 'env' name 'GLViewport';

function GLCreateTexture: GLHandle; external 'env' name 'GLCreateTexture';
procedure GLBindTexture(target, textureId: GLHandle); external 'env' name 'GLBindTexture';
procedure GLTexParameteri(target, pname, param: longword); external 'env' name 'GLTexParameteri';

procedure GLTexImage2D(
  target,
  level,
  internalFormat,
  width,
  height,
  border,
  format,
  pixelType: longword;
  pixels: pointer
); external 'env' name 'GLTexImage2D';

function GLCreateShader(shaderType: longword): longword; external 'env' name 'GLCreateShader';
procedure GLShaderSource(shaderId: GLHandle; source: PChar); external 'env' name 'GLShaderSource';
procedure GLCompileShader(shaderId: GLHandle); external 'env' name 'GLCompileShader';

function GLGetShaderParameter(shaderId: GLHandle; param: GLenum): longint; external 'env' name 'GLGetShaderParameter';
procedure GLGetShaderInfoLog(shaderId: GLHandle); external 'env' name 'GLGetShaderInfoLog';
{ High-level API for glGetShaderInfoLog }
function GetShaderInfoLog(shaderId: GLHandle): string;

function GLCreateProgram: longword; external 'env' name 'GLCreateProgram';
procedure GLAttachShader(programId: GLHandle; shader: longword); external 'env' name 'GLAttachShader';
procedure GLLinkProgram(programId: GLHandle); external 'env' name 'GLLinkProgram';
procedure GLUseProgram(programId: GLHandle); external 'env' name 'GLUseProgram';

function GLGetProgramParameter(programId: GLHandle; param: GLenum): longint; external 'env' name 'GLGetProgramParameter';
procedure GLGetProgramInfoLog(programId: longword); external 'env' name 'GLGetProgramInfoLog';
{ High-level API for glGetProgramInfoLog }
function GetProgramInfoLog(programId: longword): string;

function GLCreateBuffer: longword; external 'env' name 'GLCreateBuffer';
procedure GLBindBuffer(target: longword; bufferId: GLHandle); external 'env' name 'GLBindBuffer';
procedure GLBufferData(target: longword; size: longint; data: pointer; usage: longword); external 'env' name 'GLBufferData';
function GLGetAttribLocation(programId: longword; name: PChar): longint; external 'env' name 'GLGetAttribLocation';

procedure GLEnableVertexAttribArray(idx: longword); external 'env' name 'GLEnableVertexAttribArray';
procedure GLVertexAttribPointer(idx, size, attrType: longword; normalized: boolean; stride, offset: longint); external 'env' name 'GLVertexAttribPointer';
procedure GLDrawArrays(mode: longword; first, count: longint); external 'env' name 'GLDrawArrays';

function GLGetUniformLocation(programId: GLHandle; name: PChar): longint; external 'env' name 'GLGetUniformLocation';
procedure GLUniform1i(locationId: GLHandle; value: longint); external 'env' name 'GLUniform1i';

procedure GLActiveTexture(textureId: GLHandle); external 'env' name 'GLActiveTexture';

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
  GLGetShaderInfoLog(shaderId);
  GetShaderInfoLog := ReadInteropString
end;

function GetProgramInfoLog(programId: GLHandle): string;
begin
  GLGetProgramInfoLog(programId);
  GetProgramInfoLog := ReadInteropString
end;

procedure SetupWebGLViewport;
begin
  GLViewport(0, 0, vgaWidth, vgaHeight);
  softwareTexture := GLCreateTexture;
  GLBindTexture(GL_TEXTURE_2D, softwareTexture);

  { Enable nearest neighbour filter }
  GLTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  GLTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  GLTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  GLTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
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
  vertexShader := GLCreateShader(GL_VERTEX_SHADER);
  GLShaderSource(vertexShader, pchar(vertexSrc));
  GLCompileShader(vertexShader);

  { writelog('vertex shader id: ' + i32str(vertexShader)); }

  if GLGetShaderParameter(vertexShader, GL_COMPILE_STATUS) = 0 then
    PanicHalt('Vertex shader error: ' + GetShaderInfoLog(vertexShader))
  else
    writelog('Vertex shader has been compiled');

  { Fragment shader - samples the texture }
  fragShader := GLCreateShader(GL_FRAGMENT_SHADER);
  GLShaderSource(fragShader, pchar(fragSrc));
  GLCompileShader(fragShader);

  if GLGetShaderParameter(fragShader, GL_COMPILE_STATUS) = 0 then
    PanicHalt('Fragment shader error: ' + GetShaderInfoLog(fragShader))
  else
    writeLog('Fragment shader has been compiled');

  { Link the vertex & fragment shaders }
  defaultProgram := GLCreateProgram;
  GLAttachShader(defaultProgram, vertexShader);
  GLAttachShader(defaultProgram, fragShader);
  GLLinkProgram(defaultProgram);

  if GLGetProgramParameter(defaultProgram, GL_LINK_STATUS) = 0 then
    PanicHalt('Program link error: ' + GetProgramInfoLog(defaultProgram));

  GLUseProgram(defaultProgram);

  texLoc := GLGetUniformLocation(defaultProgram, 'u_tex');
  GLUniform1i(texLoc, 0);

  posBuffer := GLCreateBuffer;
  GLBindBuffer(GL_ARRAY_BUFFER, posBuffer);
  GLBufferData(GL_ARRAY_BUFFER, sizeof(vertices), @vertices, GL_STATIC_DRAW);

  posLoc := GLGetAttribLocation(defaultProgram, 'a_pos');
  GLEnableVertexAttribArray(posLoc);
  GLVertexAttribPointer(posLoc, 2, GL_FLOAT, false, 0, 0);
end;

{ Upload pixel data to the GPU }
procedure WebGLPresent;
begin
{
  GLClearColor(1.0, 0.4, 0.4, 1.0);
  GLClear(GL_COLOR_BUFFER_BIT);
}

  GLActiveTexture(GL_TEXTURE0);
  GLBindTexture(GL_TEXTURE_2D, softwareTexture);
  GLTexImage2D(
    GL_TEXTURE_2D, 0, GL_RGBA,
    320, 200, 0,
    GL_RGBA, GL_UNSIGNED_BYTE,
    getSurfacePtr);

  GLDrawArrays(GL_TRIANGLE_STRIP, 0, 4)
end;

end.
