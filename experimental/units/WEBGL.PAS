unit WebGL;

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
procedure glShaderSource(const shader: longword; const source: PChar); external 'env' name 'glShaderSource';
procedure glCompileShader(const shader: longword); external 'env' name 'glCompileShader';

function glCreateProgram: longword; external 'env' name 'glCreateProgram';
procedure glAttachShader(const prog, shader: longword); external 'env' name 'glAttachShader';
procedure glLinkProgram(const prog: longword); external 'env' name 'glLinkProgram';
procedure glUseProgram(const prog: longword); external 'env' name 'glUseProgram';

function glCreateBuffer: longword; external 'env' name 'glCreateBuffer';
procedure glBindBuffer(const target, buffer: longword); external 'env' name 'glBindBuffer';
procedure glBufferData(const target: longword; const size: longint; const data: pointer; const usage: longword); external 'env' name 'glBufferData';
function glGetAttribLocation(const prog: longword; const name: PChar): longint; external 'env' name 'glGetAttribLocation';

procedure glEnableVertexAttribArray(const idx: longword); external 'env' name 'glEnableVertexAttribArray';
procedure glVertexAttribPointer(const idx, size, attrType: longword; const normalized: boolean; const stride, offset: longint); external 'env' name 'glVertexAttribPointer';
procedure glDrawArrays(const mode: longword; const first, count: longint); external 'env' name 'glDrawArrays';

function glGetUniformLocation(const prog: longword; const name: PChar): longint; external 'env' name 'glGetUniformLocation';
procedure glUniform1i(const locationId, value: longint); external 'env' name 'glUniform1i';


implementation

end.