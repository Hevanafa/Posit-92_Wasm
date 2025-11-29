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

procedure glClearColor(const r, g, b, a: single); external 'env' name 'glClearColor';
procedure glClear(const mask: longword); external 'env' name 'glClear';
procedure glViewport(const x, y, width, height: longint); external 'env' name 'glViewport';

function glCreateTexture: longword; external 'env' name 'glCreateTexture';
procedure glBindTexture(const target, texture: longword); external 'env' name 'glBindTexture';
procedure glTexParameteri(const target, pname, param: longword); external 'env' name 'glTexParameteri';


implementation

end.