{
  Immediate GUI unit - Part of Posit-92 game engine
  Hevanafa
}

unit ImmediateGUI;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses
  BMFont, Shapes;

type
  TCheckboxState = record
    checked: boolean;
  end;

  TSliderState = record
    value: smallint;
  end;
  TSliderDragState = (
    SliderIdle,
    SliderHover,
    SliderDragging,
    SliderReleased
  );

  TListViewState = record
    x, y: smallint;
    selectedIndex: smallint;
  end;

const
  { Immediate GUI default theme
    https://lospec.com/palette-list/ice-cream-gb }
  IceCreamWhite = $FFFFF6D3;
  IceCreamOrange = $FFF9A875;
  IceCreamRed = $FFEB6B6F;
  IceCreamMaroon = $FF7C3F58;

procedure initImmediateGUI;

function getMousePoint: TPoint;
function getMouseJustPressed: boolean;
function getMouseJustReleased: boolean;

function getActiveFont: PBMFont;

function getHotWidget: smallint;
procedure setHotWidget(const widgetID: smallint);
function getActiveWidget: smallint;
procedure setActiveWidget(const widgetID: smallint);
function getNextWidgetID: smallint;
procedure incNextWidgetID;

{ Can be used with drawMouse }
function hasHoveredWidget: boolean;

{ Required: Called before updateMouse }
procedure updateGUILastMouseButton;

{ Required: Called after updateMouse }
procedure updateGUIMousePoint;

{ Required: Called at the end of update routine }
procedure resetWidgetIndices;

{ Required: Must be placed at the end of the draw routine }
procedure resetActiveWidget;

procedure guiSetFont(const font: TBMFont; const glyphs: array of TBMFontGlyph);

function guiMeasureText(const text: string): word;
function guiMeasureTextWrapHeight(text: ShortString; const maxWidth: smallint): word;

procedure assertFontSet;

{ Widgets }
procedure TextLabel(const text: string; const x, y: smallint);
procedure TextLabelWrap(text: ShortString; const x, y, maxWidth: smallint);
procedure CentredLabel(const text: string; const cx, y: smallint);

function Button(const caption: string; const x, y, width, height: smallint): boolean;
function ImageButton(const x, y: smallint; const imgNormal, imgHovered, imgPressed: longint): boolean;

procedure ListView(const items: array of string; var state: TListViewState);

procedure Checkbox(const caption: string; const x, y: smallint; var state: TCheckboxState);

procedure Slider(const x, y, width: smallint; var state: TSliderState; const minValue, maxValue: smallint);
function SliderDrag(const x, y, width: smallint; var state: TSliderState; const minValue, maxValue: smallint): TSliderDragState;

procedure ProgressBar(const x, y, width, height: smallint; const perc: double);
procedure ProgressBarLabelled(const x, y, width, height: smallint; const perc: double);


implementation

uses
  Conv, Graphics,
  ImgRef, ImgRefFast,
  Maths, Mouse, Panic, UStrings,
  VGA;

const
  Black = $FF000000;
  White = $FFFFFFFF;
  Red = $FFFF5555;
  DarkBlue = $FF0000AA;

var
  { Immediate GUI }
  { Additional mouse variables }
  mousePoint: TPoint;
  lastMouseButton: smallint;
  mouseJustPressed, mouseJustReleased: boolean;

  {
  activeWidget is the "memory" of what the user clicked on
  activeWidget must survive across frames
  }
  hotWidget, activeWidget, nextWidgetID: smallint;
  { Used by SliderDrag }
  lastActiveWidget: smallint;

  isFontSet: boolean;
  activeFont: TBMFont;
  activeFontGlyphs: array[32..126] of TBMFontGlyph;


procedure initImmediateGUI;
begin
  hotWidget := -1;
  activeWidget := -1;
  nextWidgetID := 0;
  lastActiveWidget := -1;

  mousePoint.x := 0;
  mousePoint.y := 0;
end;

function getMousePoint: TPoint;
begin
  getMousePoint := mousePoint
end;

function getMouseJustPressed: boolean;
begin
  getMouseJustPressed := mouseJustPressed
end;

function getMouseJustReleased: boolean;
begin
  getMouseJustReleased := mouseJustReleased
end;

function getActiveFont: PBMFont;
begin
  getActiveFont := @activeFont;
end;

function getHotWidget: smallint;
begin
  getHotWidget := hotWidget
end;

procedure setHotWidget(const widgetID: smallint);
begin
  hotWidget := widgetID
end;

function getActiveWidget: smallint;
begin
  getActiveWidget := activeWidget
end;

procedure setActiveWidget(const widgetID: smallint);
begin
  activeWidget := widgetID
end;

function getNextWidgetID: smallint;
begin
  getNextWidgetID := nextWidgetID
end;

procedure incNextWidgetID;
begin
  inc(nextWidgetID)
end;

function hasHoveredWidget: boolean;
begin
  hasHoveredWidget := hotWidget > -1
end;

procedure updateGUILastMouseButton;
begin
  lastMouseButton := mouseButton
end;

procedure updateGUIMousePoint;
begin
  mousePoint.x := mouseX;
  mousePoint.y := mouseY;

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
  lastActiveWidget := activeWidget;
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

{ Returns the width of the text
  to measure the height, use `font.lineHeight` }
function guiMeasureText(const text: string): word;
begin
  assertFontSet;
  guiMeasureText := measureBMFont(activeFont, activeFontGlyphs, text)
end;

function guiMeasureTextWrapHeight(text: ShortString; const maxWidth: smallint): word;
var
  lines: array[0..9] of ShortString;
  lineCount: smallint;
  words: array[0..99] of ShortString;
  wordCount: smallint;
  row, a: word;
  run: string;  { in the sense of something continuous / sequential }
  spaceWidth: word;
  wordWidth, runWidth: word;
begin
  assertFontSet;

  if maxWidth <= 0 then begin
    guiMeasureTextWrapHeight := 0;
    exit
  end;

  result := 0;

  { Process each line }
  text := replaceAll(text, #13#10, #10);
  lineCount := split(text, #10, lines);

  for row:=0 to lineCount - 1 do begin
    { Process each word }
    run := '';
    runWidth := 0;

    spaceWidth := guiMeasureText(' ');
    wordCount := split(lines[row], ' ', words);

    for a:=0 to wordCount - 1 do begin
      wordWidth := guiMeasureText(words[a]);

      if runWidth + wordWidth <= maxWidth then begin
        run := run + words[a] + ' ';
        inc(runWidth, wordWidth + spaceWidth)
      end else begin
        run := words[a] + ' ';
        runWidth := wordWidth + spaceWidth;
        inc(result, activeFont.lineHeight);
      end;
    end;

    inc(result, activeFont.lineHeight);
  end;

  guiMeasureTextWrapHeight := result
end;


{ Begin widgets }

procedure TextLabel(const text: string; const x, y: smallint);
begin
  assertFontSet;
  printBMFont(activeFont, activeFontGlyphs, text, x, y)
end;

procedure TextLabelWrap(text: ShortString; const x, y, maxWidth: smallint);
var
  lines: array[0..9] of ShortString;
  lineCount: smallint;
  words: array[0..99] of ShortString;
  wordCount: smallint;
  row, a: word;
  run: string;  { in the sense of something continuous / sequential }
  spaceWidth: word;
  wordWidth, runWidth: word;
  left, top: word;
begin
  assertFontSet;
  if maxWidth <= 0 then exit;

  { Process each line }
  text := replaceAll(text, #13#10, #10);
  lineCount := split(text, #10, lines);
  top := y;

  for row:=0 to lineCount - 1 do begin
    { Process each word }
    run := '';
    runWidth := 0;
    left := x;

    spaceWidth := guiMeasureText(' ');
    wordCount := split(lines[row], ' ', words);

    for a:=0 to wordCount - 1 do begin
      wordWidth := guiMeasureText(words[a]);

      if runWidth + wordWidth <= maxWidth then begin
        run := run + words[a] + ' ';
        inc(runWidth, wordWidth + spaceWidth)
      end else begin
        TextLabel(trimEnd(run), left, top);
        run := words[a] + ' ';
        runWidth := wordWidth + spaceWidth;

        left := x;
        inc(top, activeFont.lineHeight)
      end;
    end;

    if length(run) > 0 then
      TextLabel(run, left, top);

    inc(top, activeFont.lineHeight)
  end;
end;

procedure CentredLabel(const text: string; const cx, y: smallint);
var
  w: word;
begin
  w := guiMeasureText(text);
  TextLabel(text, cx - w div 2, y)
end;


function Button(const caption: string; const x, y, width, height: smallint): boolean;
var
  zone: TZone;
  thisWidgetID: smallint;
  buttonColour: longword;
begin
  assertFontSet;

  zone.x := x;
  zone.y := y;
  zone.width := width;
  zone.height := height;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if pointInZone(mousePoint, zone) then begin
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

function ImageButton(const x, y: smallint; const imgNormal, imgHovered, imgPressed: longint): boolean;
var
  zone: TZone;
  thisWidgetID: smallint;
  buttonImgHandle: longword;
begin
  assertFontSet;

  zone.x := x;
  zone.y := y;
  zone.width := getImageWidth(imgNormal);
  zone.height := getImageHeight(imgNormal);

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if pointInZone(mousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then activeWidget := thisWidgetID;
  end;

  { Render logic }
  if activeWidget = thisWidgetID then
    buttonImgHandle := imgPressed
  else if hotWidget = thisWidgetID then
    buttonImgHandle := imgHovered
  else 
    buttonImgHandle := imgNormal;

  spr(buttonImgHandle, x, y);
  { Use this in case you want your buttons have semitransparent pixels }
  { sprBlend(buttonImgHandle, x, y); }

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    ImageButton := true
  else
    ImageButton := false;
end;

procedure ListView(const items: array of string; var state: TListViewState);
var
  a: word;
  lineHeight: word;
  widgetWidth, widgetHeight: word;
  thisWidgetID: smallint;
  zone: TZone;
  clickedIndex: smallint;
begin
  assertFontSet;

  { if (items = nil) or (items.count = 0) then exit; }
  if length(items) = 0 then exit;

  lineHeight := activeFont.lineHeight + 2;
  widgetWidth := 100;
  widgetHeight := lineHeight * (length(items));

  zone.x := state.x;
  zone.y := state.y;
  zone.width := widgetWidth;
  zone.height := widgetHeight;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if pointInZone(mousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then begin
      activeWidget := thisWidgetID;

      { Calculate which item was clicked }
      clickedIndex := (mouseY - state.y) div lineHeight;
      if clickedIndex in [0..length(items)-1] then
        state.selectedIndex := clickedIndex;
    end;
  end;

  { Update Render logic }
  rectfill(state.x, state.y, state.x + widgetWidth, state.y + widgetHeight, Black);

  rectfill(
    state.x, state.y + lineHeight * state.selectedIndex,
    state.x + widgetWidth, state.y + lineHeight * (state.selectedIndex + 1), Red);

  for a:=0 to length(items)-1 do
    TextLabel(
      items[a],
      state.x + 2, state.y + 2 + lineHeight * a);

  rect(state.x, state.y, state.x + widgetWidth, state.y + widgetHeight, White);
end;

procedure Checkbox(const caption: string; const x, y: smallint; var state: TCheckboxState);
var
  zone: TZone;
  w: smallint;
  thisWidgetID: smallint;
  checkboxColour: longword;
begin
  assertFontSet;

  zone.x := x;
  zone.y := y;

  w := guiMeasureText(caption);
  zone.width := w + 6;
  zone.height := activeFont.lineHeight;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if pointInZone(mousePoint, zone) then begin
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

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then begin
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    state.checked := not state.checked;
  end;
end;


procedure Slider(const x, y, width: smallint; var state: TSliderState; const minValue, maxValue: smallint);
var
  zone: TZone;
  thisWidgetID: smallint;
  perc, range: double;
  pendingValue, thumbX: smallint;
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

  if pointInZone(mousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then activeWidget := thisWidgetID;
  end;

  { Value update logic }
  range := maxValue - minValue;
  if activeWidget = thisWidgetID then begin
    pendingValue := trunc(clamp(mouseX, x, x + width) - x);
    perc := pendingValue / width;
    state.value := round(perc * range)
  end;

  { Render logic }
  line(x, y + 2, x + width, y + 2, Black);

  perc := (state.value - minValue) / range;
  thumbX := round(x + perc * width);

  rectfill(trunc(thumbX - 2), trunc(zone.y), trunc(thumbX + 2), trunc(zone.y + 4), White);

  if activeWidget = thisWidgetID then
    { dragging }
    colour := IceCreamRed
  else if hotWidget = thisWidgetID then
    { hovering }
    colour := IceCreamOrange
  else
    colour := Black;

  rect(trunc(thumbX - 2), trunc(zone.y), trunc(thumbX + 2), trunc(zone.y + 4), colour)
end;

function SliderDrag(const x, y, width: smallint; var state: TSliderState; const minValue, maxValue: smallint): TSliderDragState;
var
  zone: TZone;
  thisWidgetID: smallint;
  perc, range: double;
  pendingValue, thumbX: smallint;
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

  if pointInZone(mousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then
      activeWidget := thisWidgetID;
  end;

  { Value update logic }
  range := maxValue - minValue;
  if activeWidget = thisWidgetID then begin
    pendingValue := trunc(clamp(mouseX, x, x + width) - x);
    perc := pendingValue / width;
    state.value := round(perc * range)
  end;

  { Render logic }
  line(x, y + 2, x + width, y + 2, Black);

  perc := (state.value - minValue) / range;
  thumbX := round(x + perc * width);

  rectfill(trunc(thumbX - 2), trunc(zone.y), trunc(thumbX + 2), trunc(zone.y + 4), White);

  if activeWidget = thisWidgetID then
    { dragging }
    colour := IceCreamRed
  else if hotWidget = thisWidgetID then
    { hovering }
    colour := IceCreamOrange
  else
    colour := Black;

  rect(trunc(thumbX - 2), trunc(zone.y), trunc(thumbX + 2), trunc(zone.y + 4), colour);

  if activeWidget = thisWidgetID then
    SliderDrag := SliderDragging
  else if lastActiveWidget = thisWidgetID then
    SliderDrag := SliderReleased
  else if hotWidget = thisWidgetID then
    SliderDrag := SliderHover
  else
    SliderDrag := SliderIdle;
end;


procedure ProgressBar(const x, y, width, height: smallint; const perc: double);
var
  w: word;
begin
  w := trunc(clamp(perc, 0.0, 1.0) * width);

  rectfill(x, y, x + width, y + height, black);
  rectfill(x, y, trunc(x + w), y + height, red);
  rect(x, y, x + width, y + height, white);
end;

procedure ProgressBarLabelled(const x, y, width, height: smallint; const perc: double);
var
  percStr: string;
  w: word;
begin
  assertFontSet;

  ProgressBar(x, y, width, height, perc);
  
  percStr := i32str(round(perc * 100)) + '%';
  w := measureBMFont(activeFont, activeFontGlyphs, percStr);
  TextLabel(percStr, x + (width - w) div 2, y + (height - activeFont.lineHeight) div 2);
end;


end.
