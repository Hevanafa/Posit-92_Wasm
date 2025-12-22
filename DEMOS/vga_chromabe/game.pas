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

var
  lastEsc, lastSpacebar: boolean;

  { Init your game state here }
  gameTime: double;
  showFilter: boolean;

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

  showFilter := true
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

  if lastSpacebar <> isKeyDown(SC_SPACE) then begin
    lastSpacebar := isKeyDown(SC_SPACE);
    if lastSpacebar then showFilter := not showFilter;
  end;

  gameTime := gameTime + dt
end;

procedure draw;
begin
  cls($FF6495ED);

  spr(imgArkRoad, 0, 0);
  if showFilter then applyFullChromabe;

  printDefault('Spacebar - Toggle chromatic aberration', 10, vgaHeight - 20);

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

