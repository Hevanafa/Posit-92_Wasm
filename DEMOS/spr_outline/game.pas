library Game;

{$Mode TP}
{$B-}

uses
  Keyboard, Mouse,
  ImgRef, ImgRefFast, Maths,
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

  { Within sprite bounds }
  for b:=0 to image^.height - 1 do
    for a:=0 to image^.width - 1 do begin
      { Skip this solid pixel }
      if unsafeSprGetAlpha(image, a, b) > 0 then continue;

      { Check 4 neighbours }
      solid := false;

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

  
  { Padding area }
  { top & bottom }
  for a:=0 to image^.width - 1 do begin
    if unsafeSprGetAlpha(image, a, 0) > 0 then
      unsafePset(x + a, y - 1, colour);

    if unsafeSprGetAlpha(image, a, image^.height - 1) > 0 then
      unsafePset(x + a, y + image^.height, colour);
  end;

  { left & right }
  for b:=0 to image^.height - 1 do begin
    if unsafeSprGetAlpha(image, 0, b) > 0 then
      unsafePset(x - 1, y + b, colour);

    if unsafeSprGetAlpha(image, image^.width - 1, b) > 0 then
      unsafePset(x + image^.width, y + b, colour);
  end;

  spr(imgHandle, x, y)
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
  a: integer;
  hue: double;
  outline: longword;

  s: string;
  w: integer;
begin
  cls($FF6495ED);

  for a:=-1 to 1 do begin
    hue := frac(getTimer + a * 0.33);
    outline := HSVtoRGB(hue, 1.0, 1.0);

    if (trunc(gameTime * 4) and 1) > 0 then
      sprOutline(imgDosuEXE[1], 148 + a * 40, 88, outline)
    else
      sprOutline(imgDosuEXE[0], 148 + a * 40, 88, outline);
  end;

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

