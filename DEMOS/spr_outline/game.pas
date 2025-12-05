library Game;

{$Mode TP}
{$B-}

uses
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

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

procedure sprOutline(const imgHandle: longint; const x, y: integer; const colour: longword);
var
  a, b: integer;
  image: PImageRef;
  solid: boolean;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  { TODO: Check bounds }
  { 1px padding is added }
  for b:=-1 to image^.height do
    for a:=-1 to image^.width do begin
      solid := false;

      { TODO: Check 4 neighbours }
      if (b - 1 >= 0) and (unsafeSprGetAlpha(image, a, b - 1) > 0) then
        solid := true;
      if (b + 1 < image^.height) and (unsafeSprGetAlpha(image, a, b + 1) > 0) then
        solid := true;

      if (a - 1 >= 0) and (unsafeSprGetAlpha(image, a - 1, b) > 0) then
        solid := true;
      if (a + 1 < image^.width) and (unsafeSprGetAlpha(image, a + 1, b) > 0) then
        solid := true;

      if solid then
        unsafePset(x + a, y + b, colour);
    end;

  spr(imgHandle, x, y)
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
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    sprOutline(imgDosuEXE[1], 148, 88, green)
  else
    sprOutline(imgDosuEXE[0], 148, 88, green);

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

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

