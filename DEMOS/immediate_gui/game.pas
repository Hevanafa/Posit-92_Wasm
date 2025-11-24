{
  Immediate GUI Implementation
  Part of Posit-92 framework
  By Hevanafa, 22-11-2025

  Based on my QB64 Immediate GUI implementation
}

library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, ImmedGui, Keyboard, Logger,
  Mouse, Panic, Shapes, Sounds,
  Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;


var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;
  clicks: word;
  showFPS: TCheckboxState;
  listItems: array[0..2] of string;

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

  initImmediateGUI;
  guiSetFont(defaultFont, defaultFontGlyphs);

  clicks := 0;

  for a:=0 to high(listItems) do
    listItems[a] := 'ListItem' + i32str(a);
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateGUILastMouseButton;
  updateMouse;
  updateGUIMouseZone;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  gameTime := gameTime + dt;

  resetWidgetIndices
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  if Button('Click me!', 180, 88, 50, 24) then
    inc(clicks);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  { spr(imgDosuEXE[0], 100, 80); }
  sprStretch(imgDosuEXE[0], 100, 80, 24, 48);

  guiSetFont(defaultFont, defaultFontGlyphs);
  s := 'Clicks: ' + i32str(clicks);
  w := guiMeasureText(s);
  TextLabel(s, (vgaWidth - w) div 2, 120);

  guiSetFont(picotronFont, picotronFontGlyphs);
  s := 'Picotron font';
  w := guiMeasureText(s);
  TextLabel(s, (vgaWidth - w) div 2, 140);

  Checkbox('Show FPS', 10, 60, showFPS);
  ListView(10, 10, listItems, 2);

  resetActiveWidget;

  drawMouse;

  if showFPS.checked then drawFPS;

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

