{
  Title: WebGL Demo
  Mixins: webgl
}

library Game;

{$Mode ObjFPC}
{$H-}

uses
  EngineCore, EngineFonts,
  Keyboard, Mouse,
  ImgRef, ImgRefFast, Logger,
  Timing, VGA, WasmMemMgr, WebGL,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  drawOnce: boolean;

{ Use this to set `done` to true }
procedure SignalDone; external 'env' name 'SignalDone';

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure OnReady;
begin
  { Initialise game state here }
  HideCursor;

  drawOnce := false
end;

procedure Update;
begin
  UpdateDeltaTime;

  UpdateMouse;

  { Your Update logic here }
  if lastEsc <> IsKeyDown(SC_ESC) then begin
    lastEsc := IsKeyDown(SC_ESC);
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
  OnReady,
  Update,
  Draw;

begin
{ Starting point is intentionally left empty }
end.

