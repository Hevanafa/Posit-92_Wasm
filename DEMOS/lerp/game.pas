library Game;

{$Mode TP}

uses
  BMFont, Conv, FPS, Graphics,
  ImgRef, Keyboard, Lerp, Logger,
  Maths, Mouse, Panic, Sounds,
  Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  SC_PAGEUP = $49;
  SC_PAGEDOWN = $51;

  CornflowerBlue = $FF6495ED;
  Cyan = $FF55FFFF;
  DarkBlue = $FF0000AA;
  Black = $FF000000;
  White = $FFFFFFFF;
  Red = $FFFF5555;
  Purple = $FFBE00FF;

  { DemoStates enum }
  DemoStateLinear = 1;

  DemoStateInQuad = 2;
  DemoStateOutQuad = 3;
  DemoStateInOutQuad = 4;
  DemoStateInSine = 5;
  DemoStateOutSine = 6;
  DemoStateInOutSine = 7;
  

var
  lastEsc, lastSpacebar: boolean;
  lastPageUp, lastPageDown: boolean;

  { Init your game state here }
  gameTime: double;
  actualDemoState: integer;
  subDemoNames: array[0..DemoStateInOutSine - 1] of string;

  startX, endX: integer;
  xLerpTimer: TLerpTimer;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  sprRef(imgCursor, mouseX, mouseY)
end;

procedure changeState(const state: integer);
begin
  actualDemoState := state;

  gameTime := 0.0;

  startX := 120;
  endX := vgaWidth - 25;
  initLerp(xLerpTimer, gameTime, 2.0);
end;

function getDemoStateName(const state: integer): string;
var
  result: string;
begin
  result := '';

  case state of
    DemoStateLinear: result := 'Linear';

    DemoStateInQuad: result := 'Quad In';
    DemoStateOutQuad: result := 'Quad Out';
    DemoStateInOutQuad: result := 'Quad In & Out';
    DemoStateInSine: result := 'Sine In';
    DemoStateOutSine: result := 'Sine Out';
    DemoStateInOutSine: result := 'Sine In & Out';
    { DemoStateAlpha: result := 'Sprite Alpha'; }
  end;

  getDemoStateName := result
end;

procedure ListView(
  const x, y: integer;
  const items: array of string;
  const selectedIndex: integer);
var
  a: word;
  lineHeight: word;
  widgetWidth, widgetHeight: word;
begin
  lineHeight := defaultFont.lineHeight + 2;

  widgetWidth := 100;
  widgetHeight := lineHeight * (high(items) + 1);

  rectfill(x, y, x + widgetWidth, y + widgetHeight, Black);

  rectfill(
    x, y + lineHeight * selectedIndex,
    x + widgetWidth, y + lineHeight * (selectedIndex + 1), Red);

  for a := 0 to high(items) do
    printDefault(
      items[a],
      x + 2, y + 2 + lineHeight * a);

  rect(x, y, x + widgetWidth, y + widgetHeight, White);
end;

function lerpColour(const colourA, colourB: longword; const perc: double): longword;
var
  a, r, g, b: byte;
begin
  a := trunc((colourA shr 24 and $FF) + perc * ((colourB shr 24 and $FF) - (colourA shr 24 and $FF)));
  r := trunc((colourA shr 16 and $FF) + perc * ((colourB shr 16 and $FF) - (colourA shr 16 and $FF)));
  g := trunc((colourA shr 8 and $FF) + perc * ((colourB shr 8 and $FF) - (colourA shr 8 and $FF)));
  b := trunc((colourA and $FF) + perc * ((colourB and $FF) - (colourA and $FF)));

  lerpColour := (a shl 24) or (r shl 16) or (g shl 8) or b
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
var
  a: integer;
begin
  { Initialise game state here }
  hideCursor;
  changeState(DemoStateInOutQuad);

  for a:=0 to high(subDemoNames) do
    subDemoNames[a] := getDemoStateName(a + 1);
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  if lastSpacebar <> isKeyDown(SC_SPACE) then begin
    lastSpacebar := isKeyDown(SC_SPACE);

    if lastSpacebar then
      initLerp(xLerpTimer, gameTime, 2.0);
  end;

  if lastPageUp <> isKeyDown(SC_PAGEUP) then begin
    lastPageUp := isKeyDown(SC_PAGEUP);

    if lastPageUp then begin
      dec(actualDemoState);
      
      if actualDemoState < 1 then actualDemoState := DemoStateInOutSine;
      changeState(actualDemoState)
    end;
  end;

  if lastPageDown <> isKeyDown(SC_PAGEDOWN) then begin
    lastPageDown := isKeyDown(SC_PAGEDOWN);

    if lastPageDown then begin
      inc(actualDemoState);

      if actualDemoState > DemoStateInOutSine then
        actualDemoState := 1;

      changeState(actualDemoState)
    end;
  end;

  gameTime := gameTime + dt
end;

procedure draw;
var
  perc: double;
  x: integer;
begin
  cls(DarkBlue);

  line(startX, 100, endX, 100, Cyan);

  perc := getLerpPerc(xLerpTimer, gameTime);

  case actualDemoState of
    DemoStateLinear:
      x := trunc(lerpLinear(startX, endX, perc));

    DemoStateInQuad:
      x := trunc(lerpEaseInQuad(startX, endX, perc));
    DemoStateOutQuad:
      x := trunc(lerpEaseOutQuad(startX, endX, perc));
    DemoStateInOutQuad:
      x := trunc(lerpEaseInOutQuad(startX, endX, perc));

    DemoStateInSine:
      x := trunc(lerpEaseInSine(startX, endX, perc));
    DemoStateOutSine:
      x := trunc(lerpEaseOutSine(startX, endX, perc));
    DemoStateInOutSine:
      x := trunc(lerpEaseInOutSine(startX, endX, perc));

    else { Not implemented defaults to Linear }
      x := trunc(lerpLinear(startX, endX, perc));
  end;

  sprAlpha(imgDosuEXE[0], startX, 88, 0.5);
  sprAlpha(imgDosuEXE[0], endX, 88, 0.5);

  if (trunc(gameTime * 4) and 1) > 0 then
    sprRef(imgDosuEXE[1], x, 88)
  else
    sprRef(imgDosuEXE[0], x, 88);

  circfill(30, 130, 10, lerpColour(Red, Purple, perc));
  circfill(60, 130, 10, HSVtoRGB(perc, 1.0, 0.5));

  { Begin HUD }
  ListView(10, 10, subDemoNames, actualDemoState - 1);

{
  s := 'Spacebar - Restart easing';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);
}
  printDefault('Spacebar - Restart easing', 8, vgaHeight - 28);
  printDefault('Page up / down - Choose between demos', 8, vgaHeight - 18);

  drawMouse;
  drawFPS;

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

