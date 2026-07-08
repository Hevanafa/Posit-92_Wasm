{
  Title: WebGL Demo
  Mixins: bmfont, sound, webgl
}

library Game;

{$Mode ObjFPC}
{$H-}

uses
  P92Core, P92Fonts, P92AssetRegistry,
  P92WasmHost, P92Logger, P92Loading,
  P92Keyboard, P92Mouse,
  P92Tex, P92TexDraw,
  P92Timing, P92VGA, P92WebGL,
  Assets;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  drawOnce: boolean;

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure LoadGameAssets;
begin
  imgCursor := RequestImage('assets/images/cursor.png');

  imgDosuExe[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuExe[1] := RequestImage('assets/images/dosu_2.png');
end;

procedure OnReady;
begin
  { Initialise game state here }
  HideCursor;

  drawOnce := false;
  gameTime := 0.0;
end;

procedure Update;
begin
  { Your Update logic here }
  if lastEsc <> IsKeyDown(SC_ESCAPE) then begin
    lastEsc := IsKeyDown(SC_ESCAPE);
    if lastEsc then SignalDone;
  end;

  gameTime := gameTime + DeltaTime;
end;

{ Draw in WebGL context }
{ Test code }
{ procedure TestDraw;
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

  PresentWebGL
end;
}


{ Draw in WebGL context }
procedure Draw;
var
  s: string;
  w: word;
begin
{
  TestDraw; exit;
}

  { CPU rendering code }
  Cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    Spr(imgDosuEXE[1], 148, 88)
  else
    Spr(imgDosuEXE[0], 148, 88);

  s := 'Hello from Posit-92 + WebAssembly + WebGL!';
  w := MeasureDefault(s);
  PrintDefault(s, (vgaWidth - w) div 2, 120);

  DrawMouse;
end;


exports
  LoadGameAssets,
  OnReady,
  Update,
  Draw;

begin
{ Starting point is intentionally left empty }
end.

