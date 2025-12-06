library Game;

{$Mode TP}

uses
  Conv, FPS, Maths,
  Keyboard, Mouse,
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

{ h, s, v: [0.0, 1.0] }
function HSVtoRGB(h, s, v: double): longword;
var
  r, g, b: byte;
  i: integer;
  f, p, q, t: double;
begin
  h := clamp(h, 0.0, 1.0);
  s := clamp(s, 0.0, 1.0);
  v := clamp(v, 0.0, 1.0);

  { Greyscale }
  if s = 0.0 then begin
    r := trunc(v * 255);
    g := r;
    b := r;
    HSVtoRGB := $FF000000 or (r shl 16) or (g shl 8) or b;
    exit
  end;

  { Convert hue to [0.0, 6.0] }
  h := h * 6.0;
  i := trunc(h);
  f := h - i;

  p := v * (1.0 - s);
  q := v * (1.0 - s * f);
  t := v * (1.0 - s * (1.0 - f));

  { Determine RGB }
  case i mod 6 of
    0: begin r := trunc(v * 255); g := trunc(t * 255); b := trunc(p * 255); end;
    1: begin r := trunc(q * 255); g := trunc(v * 255); b := trunc(p * 255); end;
    2: begin r := trunc(p * 255); g := trunc(v * 255); b := trunc(t * 255); end;
    3: begin r := trunc(p * 255); g := trunc(q * 255); b := trunc(v * 255); end;
    4: begin r := trunc(t * 255); g := trunc(p * 255); b := trunc(v * 255); end;
    5: begin r := trunc(v * 255); g := trunc(p * 255); b := trunc(q * 255); end;
  end;

  HSVtoRGB := $FF000000 or (r shl 16) or (g shl 8) or b
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
  bg: longword;
  randomCoeff: double;
  brightness, strength: double;
begin
  { Assign a randomised coefficient }
  { brightness := 1.0 + sin(getTimer * 5.0) * 0.2; }
  randomCoeff := random - 0.5;
  brightness := 1.0 + randomCoeff * 0.3;

  bg := HSVtoRGB(1 / 3.0, 1.0, 0.4 + 0.27 * (0.5 + randomCoeff));
  cls(bg);
  { cls(DarkGreen); }

  spr(imgPipBoy,
    (vgaWidth - getImageWidth(imgPipBoy)) div 2,
    (vgaHeight - getImageHeight(imgPipBoy)) div 2);

  drawFPS;
  drawMouse;

  { Apply post-processing chain }
  applyFullPhosphor(1);
  applyFullChromabe;
  applyFullSubtleScanlines;

  strength := 0.4 * brightness;
  applyFullVignette(FalloffTypeEaseOutQuad, strength);

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

