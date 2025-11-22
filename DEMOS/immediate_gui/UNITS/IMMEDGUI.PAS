unit ImmedGui;

{$Mode TP}
{$B-}

interface

procedure initImmediateGUI;

{ Called before updateMouse }
procedure updateGUILastMouseButton;

{ Called after updateMouse }
procedure updateGUIMouseZone;

{ Called at the end of update routine }
procedure resetWidgetIndices;

{ Important: Must be placed at the end of the draw routine }
procedure resetActiveWidget;

{ Widgets }
procedure TextLabel(const text: string; const x, y: integer);
function Button(const caption: string; const x, y, width, height: integer): boolean;


implementation

uses Assets, Graphics, Mouse, Shapes;

const
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


{ Begin widgets }

procedure TextLabel(const text: string; const x, y: integer);
begin
  printDefault(text, x, y)
end;

function Button(const caption: string; const x, y, width, height: integer): boolean;
var
  zone: TRect;
  thisWidgetID: integer;
  buttonColour: longword;
begin

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


end.
