library Game;

{$Mode ObjFPC}

uses
  BMFont, Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  Black = $FF000000;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;

  drawOnce: boolean;
  imgBlur: longint;

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

  gameTime := gameTime + dt;
  drawOnce := false
  
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  spr(imgDreamscapeCrossing, 0, 0);

  if not drawOnce then begin
    imgBlur := newImage(vgaWidth, vgaHeight);
    { TODO: Process from VGA }
  end;

  spr(imgBlur, 0, 0);

  s := 'Art by [Unknown Artist]';
  w := measureDefault(s);
  printBMFontColour(s,
    (vgaWidth - w) - 10, vgaHeight - 20,
    defaultFont, defaultFontGlyphs, black);

  drawMouse;
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

