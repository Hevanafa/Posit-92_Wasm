library Game;

{$Mode TP}

uses
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  imgVignette: longint;
  imgVignettePtr: PImageRef;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure applyFullVignette;
var
  px, py: integer;
  centreX, centreY: double;
  offsetX, offsetY: double;
  normX, normY: double;
  dist, t, factor: double;
  a, r, g, b: byte;
  colour: longword;
begin
  if imgVignettePtr = nil then begin
    imgVignette := newImage(vgaWidth, vgaHeight);
    imgVignettePtr := getImagePtr(imgVignette);
  end;

  for py:=0 to vgaHeight - 1 do 
  for px:=0 to vgaWidth - 1 do begin
    { Coordinate normalisation }
    centreX := vgaWidth / 2;
    centreY := vgaHeight / 2;

    offsetX := px - centreX;
    offsetY := py - centreY;

    normX := offsetX / centreX;
    normY := offsetY / centreY;

    { Elliptical distance }
    dist := sqrt(normX * normX + normY * normY);

    { Vignette factor (falloff) }
    { t: gradient }
    t := 1.0 - dist;
    if t < 0.0 then t := 0.0;
    if t > 1.0 then t := 1.0;
    factor := t * t * (3.0 - 2.0 * t);

    { Darken RGB channels with vignette factor }
    colour := unsafePget(px, py);

    r := colour shr 16 and $FF;
    g := colour shr 8 and $FF;
    b := colour and $FF;
    a := colour shr 24 and $FF;

    r := trunc(r * factor);
    g := trunc(g * factor);
    b := trunc(b * factor);

    { Render to buffer }
    colour := (a shl 24) or (r shl 16) or (g shl 8) or b;
    unsafeSprPset(imgVignettePtr, px, py, colour)
  end;

  spr(imgVignette, 0, 0)
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

  spr(imgArkRoad, 0, 0);

  applyFullVignette;

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

