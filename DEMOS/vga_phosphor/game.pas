library Game;

{$Mode ObjFPC}

uses
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  PostProc, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  CornflowerBlue = $FF6495ED;
  Black = $FF181818;

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


procedure init;
begin
  initBuffer;
  initDeltaTime;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;
end;

procedure update;
begin
  updateDeltaTime;

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
  cls(Black);

  spr(imgPipBoy, 0, 0);

  applyFullPhosphor(1);

  drawMouse;
  vgaFlush
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

