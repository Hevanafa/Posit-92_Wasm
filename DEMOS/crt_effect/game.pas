library Game;

{$Mode TP}

uses
  Conv, FPS, Keyboard, Mouse,
  ImgRef, ImgRefFast,
  PostProc, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  Black = $FF181818;
  DarkGreen = $FF00AA00;
  Green = $FF55FF55;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;


procedure init;
begin
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then signalDone;
  end;

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls(DarkGreen);

  spr(imgPipBoy,
    (vgaWidth - getImageWidth(imgPipBoy)) div 2,
    (vgaHeight - getImageHeight(imgPipBoy)) div 2);

  drawFPS;
  drawMouse;

  { Apply post-processing chain }
  applyFullPhosphor(1);
  applyFullChromabe;
  applyFullSubtleScanlines;
  
  { This one's bugged }
  applyFullVignette(FalloffTypeEaseOutQuad, 0.4);

  flush
end;

exports
  { Main game procedures }
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

