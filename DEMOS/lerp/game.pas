library Game;

{$Mode TP}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, Keyboard, Lerp, Logger,
  Mouse, Panic, Sounds, Timing,
  VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  CornflowerBlue = $FF6495ED;
  Cyan = $FF55FFFF;
  Black = $FF000000;
  White = $FFFFFFFF;
  Red = $FFFF5555;

  { DemoStates enum }
  DemoStateLinear = 1;
  DemoStateInQuad = 2;
  DemoStateOutQuad = 3;
  DemoStateInOutQuad = 4;

var
  lastEsc, lastSpacebar: boolean;

  { Init your game state here }
  gameTime: double;
  actualDemoState: integer;
  subDemoNames: array[0..DemoStateInOutQuad - 1] of string;

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
  spr(imgCursor, mouseX, mouseY)
end;

procedure changeState(const state: integer);
begin
  actualDemoState := state;

  gameTime := 0.0;

  startX := 70;
  endX := vgaWidth - 70;
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

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;

  perc: double;
  x: integer;
begin
  cls(CornflowerBlue);

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

    else { Not implemented defaults to Linear }
      x := trunc(lerpLinear(startX, endX, perc));
  end;

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], x, 88)
  else
    spr(imgDosuEXE[0], x, 88);


  { Begin HUD }
  ListView(10, 10, subDemoNames, actualDemoState - 1);

  s := 'Spacebar - Restart easing';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

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

