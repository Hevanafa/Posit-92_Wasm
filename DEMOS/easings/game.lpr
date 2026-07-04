library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Fonts, P92WasmHost, P92AssetRegistry,
  P92Colour, P92FPS,
  P92Graphics,
  P92SoftwareTex, P92SoftwareTexDraw, P92SoftwareTexComp,
  P92Keyboard, P92Mouse,
  P92Easings, P92Logger, P92Maths,
  P92Timing, P92VGA,
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

  { Game state variables }
  gameTime: double;
  actualDemoState: integer;
  subDemoNames: array[0..DemoStateInOutSine - 1] of string;

  startX, endX: integer;
  xEasingTimer: TEasingTimer;

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure LoadGameAssets;
begin
  RequestBMFont('assets/fonts/nokia_cellphone_fc_8.txt', DefaultFontPtr, DefaultFontGlyphsPtr);

  imgCursor := RequestImage('assets/images/cursor.png');

  imgDosuExe[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuExe[1] := RequestImage('assets/images/dosu_2.png');
end;

function GetDemoStateName(const state: integer): string;
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

  GetDemoStateName := result
end;

procedure changeState(const state: integer);
begin
  actualDemoState := state;

  gameTime := 0.0;

  startX := 120;
  endX := vgaWidth - 25;
  InitEasing(xEasingTimer, gameTime, 2.0);
end;

procedure OnReady;
var
  a: word;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  gameTime := 0.0;

  changeState(DemoStateInOutQuad);

  for a:=0 to high(subDemoNames) do
    subDemoNames[a] := GetDemoStateName(a + 1);
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
  lineHeight := DefaultFontPtr^.lineHeight + 2;

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


procedure Update;
begin
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
      InitEasing(xEasingTimer, gameTime, 2.0);
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

  gameTime := gameTime + DeltaTime;
end;

procedure Draw;
var
  perc: double;
  x: integer;
begin
  Cls(DarkBlue);

  Line(startX, 100, endX, 100, Cyan);

  perc := GetEasingPerc(xEasingTimer, gameTime);

  case actualDemoState of
    DemoStateLinear:
      x := trunc(LerpLinear(startX, endX, perc));

    DemoStateInQuad:
      x := trunc(LerpEaseInQuad(startX, endX, perc));
    DemoStateOutQuad:
      x := trunc(LerpEaseOutQuad(startX, endX, perc));
    DemoStateInOutQuad:
      x := trunc(LerpEaseInOutQuad(startX, endX, perc));

    DemoStateInSine:
      x := trunc(LerpEaseInSine(startX, endX, perc));
    DemoStateOutSine:
      x := trunc(LerpEaseOutSine(startX, endX, perc));
    DemoStateInOutSine:
      x := trunc(LerpEaseInOutSine(startX, endX, perc));

    else { Not implemented defaults to Linear }
      x := trunc(LerpLinear(startX, endX, perc));
  end;

  SprAlpha(imgDosuEXE[0], startX, 88, 0.5);
  SprAlpha(imgDosuEXE[0], endX, 88, 0.5);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], x, 88)
  else
    spr(imgDosuEXE[0], x, 88);

  circfill(30, 130, 10, LerpColour(Red, Purple, perc));
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

  DrawMouse;
  drawFPS;

  VgaUpload;
  VgaPresent
end;

exports
  LoadGameAssets, OnReady, Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

