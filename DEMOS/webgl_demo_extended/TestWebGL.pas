library TestWebGL;

uses WebGL;

procedure init;
begin
  glViewport(0, 0, 320, 200);
  glClearColor(0.2, 0.4, 0.8, 1.0);
  glClear(GL_COLOR_BUFFER_BIT)
end;

exports
  init;

begin
{ Starting point is intentionally left empty }
end.
