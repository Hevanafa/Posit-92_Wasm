{
  Immediate GUI unit
  Part of Posit-92 framework
  By Hevanafa, 23-11-2025
  Update: 23-11-2025
}

unit ImmedGui;

{$Mode TP}
{$B-}

interface

uses BMFont;

type
  TCheckboxState = record
    checked: boolean;
  end;
  TSliderState = record
    value: integer;
  end;

procedure initImmediateGUI;

{ Called before updateMouse }
procedure updateGUILastMouseButton;

{ Called after updateMouse }
procedure updateGUIMouseZone;

{ Called at the end of update routine }
procedure resetWidgetIndices;

{ Important: Must be placed at the end of the draw routine }
procedure resetActiveWidget;

procedure guiSetFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
function guiMeasureText(const text: string): word;

function hasHoveredWidget: boolean;

{ Widgets }
procedure TextLabel(const text: string; const x, y: integer);
function Button(const caption: string; const x, y, width, height: integer): boolean;
procedure ListView(
  const x, y: integer;
  const items: array of string;
  const selectedIndex: integer);
procedure Checkbox(const caption: string; const x, y: integer; var state: TCheckboxState);
procedure Slider(const x, y, width: integer; var state: TSliderState; const minValue, maxValue: integer);


implementation

uses Graphics, Mouse, Panic, Shapes;

const
  Black = $FF000000;
  White = $FFFFFFFF;
  Red = $FFFF5555;
  
{ Immediate GUI default theme
  https://lospec.com/palette-list/ice-cream-gb }
  IceCreamWhite = $FFFFF6D3;
  IceCreamOrange = $FFF9A875;
  IceCreamRed = $FFEB6B6F;
  IceCreamMaroon = $FF7C3F58;

var
  { Immediate GUI }
  { Additional mouse variables }
  mouseZone: TRect;
  lastMouseButton: integer;
  mouseJustPressed, mouseJustReleased: boolean;

  {
  activeWidget is the "memory" of what the user clicked on
  activeWidget must survive across frames
  }
  hotWidget, activeWidget, nextWidgetID: integer;

  isFontSet: boolean;
  activeFont: TBMFont;
  activeFontGlyphs: array[32..126] of TBMFontGlyph;


procedure initImmediateGUI;
begin
  hotWidget := -1;
  activeWidget := -1;
  nextWidgetID := 0;

  mouseZone.x := 0;
  mouseZone.y := 0;
  mouseZone.width := 1;
  mouseZone.height := 1;
end;

procedure updateGUILastMouseButton;
begin
  lastMouseButton := mouseButton
end;

procedure updateGUIMouseZone;
begin
  mouseZone.x := mouseX;
  mouseZone.y := mouseY;

  mouseJustPressed := (mouseButton <> MouseButtonNone) and (lastMouseButton = MouseButtonNone);
  mouseJustReleased := (mouseButton = MouseButtonNone) and (lastMouseButton <> MouseButtonNone)
end;

procedure resetWidgetIndices;
begin
  hotWidget := -1;
  { Important: Do not reset activeWidget on each frame }
  { activeWidget := -1; }
  nextWidgetID := 0;
end;

procedure resetActiveWidget;
begin
  if mouseJustReleased and (activeWidget >= 0) then activeWidget := -1;
end;

procedure guiSetFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);
var
  a: word;
begin
  isFontSet := true;
  activeFont := font;

  for a := 32 to 126 do
    activeFontGlyphs[a] := glyphs[a - 32];
end;

procedure assertFontSet;
begin
  if not isFontSet then panicHalt('activeFont is unset!');
end;

function guiMeasureText(const text: string): word;
begin
  assertFontSet;
  guiMeasureText := measureBMFont(text, activeFontGlyphs)
end;

function hasHoveredWidget: boolean;
begin
  hasHoveredWidget := hotWidget > -1
end;


{ Begin widgets }

procedure TextLabel(const text: string; const x, y: integer);
begin
  assertFontSet;
  printBMFont(text, x, y, activeFont, activeFontGlyphs)
end;

function Button(const caption: string; const x, y, width, height: integer): boolean;
var
  zone: TRect;
  thisWidgetID: integer;
  buttonColour: longword;
begin
  assertFontSet;

  zone.x := x;
  zone.y := y;
  zone.width := width;
  zone.height := height;

  { Update logic }
  thisWidgetID := nextWidgetID;
  nextWidgetID := nextWidgetID + 1;

  if rectIntersects(zone, mouseZone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then activeWidget := thisWidgetID;
  end;

  { Render logic }
  if activeWidget = thisWidgetID then
    buttonColour := IceCreamRed
  else if hotWidget = thisWidgetID then
    buttonColour := IceCreamOrange
  else 
    buttonColour := IceCreamWhite;

  rectfill(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), buttonColour);
  rect(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), IceCreamWhite);
  TextLabel(caption, trunc(zone.x + 4), trunc(zone.y + 4));

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    Button := true
  else
    Button := false;
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
  assertFontSet;

  lineHeight := activeFont.lineHeight + 2;

  widgetWidth := 100;
  widgetHeight := lineHeight * (high(items) + 1);

  rectfill(x, y, x + widgetWidth, y + widgetHeight, Black);

  rectfill(
    x, y + lineHeight * selectedIndex,
    x + widgetWidth, y + lineHeight * (selectedIndex + 1), Red);

  for a := 0 to high(items) do
    TextLabel(
      items[a],
      x + 2, y + 2 + lineHeight * a);

  rect(x, y, x + widgetWidth, y + widgetHeight, White);
end;

procedure Checkbox(const caption: string; const x, y: integer; var state: TCheckboxState);
var
  zone: TRect;
  w: integer;
  thisWidgetID: integer;
  checkboxColour: longword;
begin
  assertFontSet;

  zone.x := x;
  zone.y := y;

  w := measureBMFont(caption, activeFontGlyphs);
  zone.width := w + 6;
  zone.height := activeFont.lineHeight;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if rectIntersects(zone, mouseZone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then activeWidget := thisWidgetID;
  end;

  { Render logic }
  if state.checked then
    rectfill(trunc(zone.x), trunc(zone.y), trunc(zone.x + 5), trunc(zone.y + 5), Black)
  else
    rectfill(trunc(zone.x), trunc(zone.y), trunc(zone.x + 5), trunc(zone.y + 5), White);

  if activeWidget = thisWidgetID then
    { on held down }
    checkboxColour := IceCreamRed
  else if hotWidget = thisWidgetID then
    { on hover }
    checkboxColour := IceCreamOrange
  else
    checkboxColour := Black;

  rect(trunc(zone.x), trunc(zone.y), trunc(zone.x + 5), trunc(zone.y + 5), checkboxColour);
  TextLabel(caption, trunc(zone.x + 7), trunc(zone.y));

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    state.checked := not state.checked;
end;


procedure Slider(const x, y, width: integer; var state: TSliderState; const minValue, maxValue: integer);
var
  zone: TRect;
  thisWidgetID: integer;
  perc, range: double;
  pendingValue, thumbX: integer;
  colour: longword;
begin
  if minValue >= maxValue then panicHalt('Slider: minValue has to be less than maxValue!');

  zone.x := x;
  zone.y := y;
  zone.width := width;
  zone.height := 5;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if rectIntersects(zone, mouseZone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then activeWidget := thisWidgetID;
  end;

  { TODO: Value update logic }
  { TODO: Render logic }

end;

end.
