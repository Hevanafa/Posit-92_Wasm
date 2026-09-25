{
  Easings demo
  Mixins: bmfont, sound
}

library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Fonts, P92WasmHost, P92AssetRegistry,
  P92Colour, P92FPS, P92BMFont,
  P92Graphics,
  P92Tex, P92TexDraw, P92TexComp,
  P92Keyboard, P92Mouse, P92Loading,
  P92Easings, P92Logger, P92Maths,
  P92Timing, P92VGA,
  Assets;

const
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

procedure OnPreload;
begin
  texDosuEXE[0] := RequestImage('assets/images/dosu_1.png');
  texDosuEXE[1] := RequestImage('assets/images/dosu_2.png');
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

procedure ChangeState(const state: integer);
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
  HideCursor;

  { Initialise game state here }
  gameTime := 0.0;

  ChangeState(DemoStateInOutQuad);

  for a:=0 to high(subDemoNames) do
    subDemoNames[a] := GetDemoStateName(a + 1);
end;


procedure ListView(
  const x, y: integer;
  const items: array of string;
  const selectedIndex: integer);
var
  a: word;
  fontPtr: PBMFont;
  lineHeight: word;
  widgetWidth, widgetHeight: word;
begin
  fontPtr := BorrowBMFontPtr(GetDefaultFontHandle);
  lineHeight := fontPtr^.lineHeight + 2;

  widgetWidth := 100;
  widgetHeight := lineHeight * (high(items) + 1);

  RectFill(x, y, x + widgetWidth, y + widgetHeight, Black);

  RectFill(
    x, y + lineHeight * selectedIndex,
    x + widgetWidth, y + lineHeight * (selectedIndex + 1), Red);

  for a := 0 to high(items) do
    PrintDefault(
      items[a],
      x + 2, y + 2 + lineHeight * a);

  Rect(x, y, x + widgetWidth, y + widgetHeight, White);
end;


procedure Update;
begin
  if lastEsc <> isKeyDown(SC_ESCAPE) then begin
    lastEsc := isKeyDown(SC_ESCAPE);

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
      ChangeState(actualDemoState)
    end;
  end;

  if lastPageDown <> isKeyDown(SC_PAGEDOWN) then begin
    lastPageDown := isKeyDown(SC_PAGEDOWN);

    if lastPageDown then begin
      inc(actualDemoState);

      if actualDemoState > DemoStateInOutSine then
        actualDemoState := 1;

      ChangeState(actualDemoState)
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

  SprAlpha(texDosuEXE[0], startX, 88, 0.5);
  SprAlpha(texDosuEXE[0], endX, 88, 0.5);

  if (trunc(gameTime * 4) and 1) > 0 then
    Spr(texDosuEXE[1], x, 88)
  else
    Spr(texDosuEXE[0], x, 88);

  CircFill(30, 130, 10, LerpColour(Red, Purple, perc));
  CircFill(60, 130, 10, HSVtoRGB(perc, 1.0, 0.5));

  { HUD }

  ListView(10, 10, subDemoNames, actualDemoState - 1);

  PrintDefault('Spacebar - Restart easing', 8, vgaHeight - 28);
  PrintDefault('Page up / down - Choose between demos', 8, vgaHeight - 18);
end;

procedure Init;
var
  appConfig: TP92AppConfig;
begin
  appConfig := DefaultP92AppConfig;

  P92Start(appConfig);
end;

exports
  Init, OnPreload, OnReady, Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

