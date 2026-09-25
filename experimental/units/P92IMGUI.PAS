{
  Immediate Mode GUI unit
  Part of Posit-92 game engine

  Convention:
  - `x` and `y` are the origin
  - `width` and `height` are the size
  - Render logic must use `width - 1` adjustment, and `height - 1` if applicable
  - As for the hit test, prefer using `PointInZone`

  So, the range is like this:
  x is 0% (origin) and width is 100%
}

unit P92IMGUI;

{$Mode ObjFPC}
{$H+}{$J-}

interface

{$ifdef P92_IMGUI}
uses
  P92AssetHandles, P92BMFont, P92Geometry;

type
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
  { Accent colours based on Specimen P-92 }

  AccentNormal = $FF8CDE92;
  AccentDark = $FF04601C;
  AccentPale = $FFDEF6B8;

procedure InitImmediateGUI(useDefaultFont: boolean = true);

function GetMouseJustPressed: boolean;
function GetMouseJustReleased: boolean;

function GetGUIActiveFontHandle: TBMFontHandle;

function GetHotWidget: smallint;
procedure SetHotWidget(const widgetID: smallint);
function GetActiveWidget: smallint;
procedure SetActiveWidget(const widgetID: smallint);
function GetNextWidgetID: smallint;
procedure IncNextWidgetID;

function AcquireNextWidgetID: smallint;

{ Can be used with DrawMouse }
function HasHoveredWidget: boolean;

{ Required: Called before UpdateMouse }
procedure UpdateGUILastMouseButton;

{ Required: Called after UpdateMouse }
procedure UpdateGUIMouseState;

{ Required: Called at the end of update routine }
procedure ResetWidgetIndices;

{ Required: Must be placed at the end of the draw routine }
procedure ResetActiveWidget;

procedure GUISetFont(const fontHandle: TBMFontHandle);

function GUIMeasureText(const text: string): smallint;
function GuiMeasureTextWrapHeight(text: ShortString; const maxWidth: smallint): smallint;

procedure GUIAssertFontSet;

{ Widgets }
procedure TextLabel(const text: string; const x, y: smallint);
procedure TextLabelWrap(text: ShortString; const x, y, maxWidth: smallint);
procedure CentredLabel(const text: string; const cx, y: smallint);

function Button(const caption: string; const x, y: smallint): boolean;
function ButtonSized(const caption: string; const x, y, width, height: smallint): boolean;

function ImageButton(
  const x, y: smallint;
  const texNormal, texHovered, texPressed: TTextureHandle
): boolean;

procedure ListView(const items: array of string; var state: TListViewState);

procedure Checkbox(const caption: string; const x, y: smallint; var state: boolean);

procedure Slider(
  const x, y, width: smallint;
  var state: smallint;
  const minValue, maxValue: smallint
);

function SliderDrag(const x, y, width: smallint; var state: smallint; const minValue, maxValue: smallint): TSliderDragState;

procedure ProgressBar(const x, y, width, height: smallint; const perc: double);
procedure ProgressBarLabelled(const x, y, width, height: smallint; const perc: double);
{$endif}


implementation

{$ifdef P92_IMGUI}
uses
  P92Fonts, P92AssetRegistry,
  P92Conversions, P92Graphics,
  P92Tex, P92TexDraw,
  P92Maths, P92Mouse, P92Panic, P92Strings,
  P92VGA;

const
  Black = $FF000000;
  White = $FFFFFFFF;
  Red = $FFFF5555;
  DarkBlue = $FF0000AA;

var
  { Immediate GUI }
  { Additional mouse variables }
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
  activeFontHandle: TBMFontHandle;


procedure InitImmediateGUI(useDefaultFont: boolean);
begin
  hotWidget := -1;
  activeWidget := -1;
  nextWidgetID := 0;
  lastActiveWidget := -1;

  isFontSet := false;

  if useDefaultFont then
    GUISetFont(GetDefaultFontHandle)
  else
    GUISetFont(0);
end;

function GetMouseJustPressed: boolean;
begin
  GetMouseJustPressed := mouseJustPressed
end;

function GetMouseJustReleased: boolean;
begin
  GetMouseJustReleased := mouseJustReleased
end;

function GetGUIActiveFontHandle: TBMFontHandle;
begin
  GetGUIActiveFontHandle := activeFontHandle
end;

function GetHotWidget: smallint;
begin
  GetHotWidget := hotWidget
end;

procedure SetHotWidget(const widgetID: smallint);
begin
  hotWidget := widgetID
end;

function GetActiveWidget: smallint;
begin
  GetActiveWidget := activeWidget
end;

procedure SetActiveWidget(const widgetID: smallint);
begin
  activeWidget := widgetID
end;

function GetNextWidgetID: smallint;
begin
  GetNextWidgetID := nextWidgetID
end;

procedure IncNextWidgetID;
begin
  inc(nextWidgetID)
end;

function AcquireNextWidgetID: smallint;
begin
  AcquireNextWidgetID := nextWidgetID;
  inc(nextWidgetID)
end;

function HasHoveredWidget: boolean;
begin
  HasHoveredWidget := hotWidget > -1
end;

procedure UpdateGUILastMouseButton;
begin
  lastMouseButton := GetMouseButton;
end;

procedure UpdateGUIMouseState;
begin
  mouseJustPressed := (GetMouseButton <> MouseButtonNone) and (lastMouseButton = MouseButtonNone);
  mouseJustReleased := (GetMouseButton = MouseButtonNone) and (lastMouseButton <> MouseButtonNone)
end;

procedure ResetWidgetIndices;
begin
  hotWidget := -1;
  { Important: Do not reset activeWidget on each frame }
  { activeWidget := -1; }
  nextWidgetID := 0;
end;

procedure ResetActiveWidget;
begin
  lastActiveWidget := activeWidget;
  if mouseJustReleased and (activeWidget >= 0) then activeWidget := -1;
end;

procedure GUISetFont(const fontHandle: TBMFontHandle);
begin
  isFontSet := fontHandle >= 1;
  activeFontHandle := fontHandle
end;

procedure GUIAssertFontSet;
begin
  if not isFontSet then
    PanicHalt('Immediate GUI: activeFont is unset!');
end;

{ Returns the width of the text
  to measure the height, use `font.lineHeight` }
function GUIMeasureText(const text: string): smallint;
begin
  GUIAssertFontSet;
  GUIMeasureText := MeasureBMFont(activeFontHandle, text)
end;

function GuiMeasureTextWrapHeight(text: ShortString; const maxWidth: smallint): smallint;
var
  fontPtr: PBMFont;
  lines: array[0..9] of ShortString;
  lineCount: smallint;
  words: array[0..99] of ShortString;
  wordCount: smallint;
  row, a: word;
  run: string;  { in the sense of something continuous / sequential }
  spaceWidth: word;
  wordWidth, runWidth: word;
begin
  GUIAssertFontSet;

  if maxWidth <= 0 then begin
    GuiMeasureTextWrapHeight := 0;
    exit
  end;

  fontPtr := BorrowBMFontPtr(activeFontHandle);

  result := 0;

  { Process each line }
  text := replaceAll(text, #13#10, #10);
  lineCount := split(text, #10, lines);

  for row:=0 to lineCount - 1 do begin
    { Process each word }
    run := '';
    runWidth := 0;

    spaceWidth := GUIMeasureText(' ');
    wordCount := split(lines[row], ' ', words);

    for a:=0 to wordCount - 1 do begin
      wordWidth := GUIMeasureText(words[a]);

      if runWidth + wordWidth <= maxWidth then begin
        run := run + words[a] + ' ';
        inc(runWidth, wordWidth + spaceWidth)
      end else begin
        run := words[a] + ' ';
        runWidth := wordWidth + spaceWidth;
        inc(result, fontPtr^.lineHeight);
      end;
    end;

    inc(result, fontPtr^.lineHeight);
  end;

  GuiMeasureTextWrapHeight := result
end;


{ Begin widgets }

procedure TextLabel(const text: string; const x, y: smallint);
begin
  GUIAssertFontSet;
  printBMFont(activeFontHandle, text, x, y)
end;

procedure TextLabelWrap(text: ShortString; const x, y, maxWidth: smallint);
var
  fontPtr: PBMFont;
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
  GUIAssertFontSet;

  if maxWidth <= 0 then exit;

  fontPtr := BorrowBMFontPtr(activeFontHandle);

  { Process each line }
  text := replaceAll(text, #13#10, #10);
  lineCount := split(text, #10, lines);
  top := y;

  for row:=0 to lineCount - 1 do begin
    { Process each word }
    run := '';
    runWidth := 0;
    left := x;

    spaceWidth := GUIMeasureText(' ');
    wordCount := split(lines[row], ' ', words);

    for a:=0 to wordCount - 1 do begin
      wordWidth := GUIMeasureText(words[a]);

      if runWidth + wordWidth <= maxWidth then begin
        run := run + words[a] + ' ';
        inc(runWidth, wordWidth + spaceWidth)
      end else begin
        TextLabel(trimEnd(run), left, top);
        run := words[a] + ' ';
        runWidth := wordWidth + spaceWidth;

        left := x;
        inc(top, fontPtr^.lineHeight)
      end;
    end;

    if length(run) > 0 then
      TextLabel(run, left, top);

    inc(top, fontPtr^.lineHeight)
  end;
end;

procedure CentredLabel(const text: string; const cx, y: smallint);
var
  w: word;
begin
  w := GUIMeasureText(text);
  TextLabel(text, cx - w div 2, y)
end;


function Button(const caption: string; const x, y: smallint): boolean;
const
  Padding = 4;
var
  w: smallint;
begin
  GUIAssertFontSet;

  w := GUIMeasureText(caption);

  Button := ButtonSized(caption,
    x, y,
    w + Padding * 2,
    BorrowBMFontPtr(activeFontHandle)^.lineHeight + Padding * 2);
end;

function ButtonSized(const caption: string; const x, y, width, height: smallint): boolean;
const
  Padding = 4;
var
  zone: TZone;
  thisWidgetID: smallint;
  buttonColour: longword;
begin
  GUIAssertFontSet;

  zone.x := x;
  zone.y := y;
  zone.width := width;
  zone.height := height;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if PointInZone(GetMousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then activeWidget := thisWidgetID;
  end;

  { Render logic }
  if activeWidget = thisWidgetID then
    buttonColour := AccentDark
  else if hotWidget = thisWidgetID then
    buttonColour := AccentPale
  else 
    buttonColour := AccentNormal;

  RectFill(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), buttonColour);
  Rect(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), AccentDark);
  TextLabel(caption, trunc(zone.x + Padding), trunc(zone.y + Padding));

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    ButtonSized := true
  else
    ButtonSized := false;
end;

function ImageButton(
  const x, y: smallint;
  const texNormal, texHovered, texPressed: TTextureHandle
): boolean;
var
  zone: TZone;
  thisWidgetID: smallint;
  texHandle: longword;
begin
  GUIAssertFontSet;

  zone.x := x;
  zone.y := y;
  zone.width := GetTexWidth(texNormal);
  zone.height := GetTexHeight(texNormal);

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if PointInZone(GetMousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then activeWidget := thisWidgetID;
  end;

  { Render logic }
  if activeWidget = thisWidgetID then
    texHandle := texPressed
  else if hotWidget = thisWidgetID then
    texHandle := texHovered
  else 
    texHandle := texNormal;

  spr(texHandle, x, y);
  { Use this in case you want your buttons have semitransparent pixels }
  { sprBlend(texHandle, x, y); }

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    ImageButton := true
  else
    ImageButton := false;
end;

procedure ListView(const items: array of string; var state: TListViewState);
var
  fontPtr: PBMFont;
  a: word;
  lineHeight: word;
  widgetWidth, widgetHeight: word;
  thisWidgetID: smallint;
  zone: TZone;
  clickedIndex: smallint;
begin
  GUIAssertFontSet;

  if length(items) = 0 then exit;

  fontPtr := BorrowBMFontPtr(activeFontHandle);

  lineHeight := fontPtr^.lineHeight + 2;
  widgetWidth := 100;
  widgetHeight := lineHeight * (length(items));

  zone.x := state.x;
  zone.y := state.y;
  zone.width := widgetWidth;
  zone.height := widgetHeight;

  { Update logic }

  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if PointInZone(GetMousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then begin
      activeWidget := thisWidgetID;

      { Calculate which item was clicked }
      clickedIndex := (GetMouseY - state.y) div lineHeight;
      if clickedIndex in [0..length(items)-1] then
        state.selectedIndex := clickedIndex;
    end;
  end;

  { Render logic }

  RectFill(
    state.x, state.y,
    state.x + widgetWidth - 1, state.y + widgetHeight - 1,
    AccentDark);

  RectFill(
    state.x, state.y + lineHeight * state.selectedIndex,
    state.x + widgetWidth - 1, state.y + lineHeight * (state.selectedIndex + 1) - 1,
    AccentNormal);

  for a:=0 to length(items)-1 do
    TextLabel(
      items[a],
      state.x + 2, state.y + 2 + lineHeight * a);

  Rect(
    state.x, state.y,
    state.x + widgetWidth - 1, state.y + widgetHeight - 1,
    AccentPale);
end;

procedure Checkbox(const caption: string; const x, y: smallint; var state: boolean);
const
  Width = 7;
  Height = 7;
  Spacing = 2;
var
  fontPtr: PBMFont;
  zone: TZone;
  textWidth: smallint;
  thisWidgetID: smallint;
  checkboxColour: longword;
begin
  GUIAssertFontSet;

  fontPtr := BorrowBMFontPtr(activeFontHandle);

  zone.x := x;
  zone.y := y;

  textWidth := GUIMeasureText(caption);
  zone.width := Width + Spacing + textWidth;
  zone.height := fontPtr^.lineHeight;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if PointInZone(GetMousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then activeWidget := thisWidgetID;
  end;

  { Render logic }
  if state then
    RectFill(
      trunc(zone.x), trunc(zone.y),
      trunc(zone.x + Width - 1), trunc(zone.y + Height - 1), AccentDark)
  else
    RectFill(
      trunc(zone.x), trunc(zone.y),
      trunc(zone.x + Width - 1), trunc(zone.y + Height - 1), AccentPale);

  if activeWidget = thisWidgetID then
    { on held down }
    checkboxColour := AccentDark
  else if hotWidget = thisWidgetID then
    { on hover }
    checkboxColour := AccentNormal
  else
    checkboxColour := AccentDark;

  Rect(
    trunc(zone.x), trunc(zone.y),
    trunc(zone.x + Width - 1), trunc(zone.y + Width - 1), checkboxColour);

  TextLabel(caption, trunc(zone.x + Width + Spacing), trunc(zone.y));

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then begin
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    state := not state;
  end;
end;


procedure Slider(
  const x, y, width: smallint;
  var state: smallint;
  const minValue, maxValue: smallint
);
const
  Height = 7;
var
  zone: TZone;
  thisWidgetID: smallint;
  perc, range: double;
  pendingValue, thumbX: smallint;
  colour: longword;
begin
  if minValue >= maxValue then
    PanicHalt('Slider: minValue has to be less than maxValue!');

  zone.x := x;
  zone.y := y;
  zone.width := width;
  zone.height := Height;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if PointInZone(GetMousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then activeWidget := thisWidgetID;
  end;

  { Value update logic }
  range := maxValue - minValue;

  if activeWidget = thisWidgetID then begin
    pendingValue := trunc(
      clamp(GetMouseX, x, x + width) - x);
    perc := pendingValue / width;
    state := round(perc * range)
  end;

  { Render logic }

  perc := (state - minValue) / range;
  thumbX := round(x + perc * width);

  Line(
    x, y + 3,
    x + width - 1, y + 3, AccentDark);

  RectFill(
    trunc(thumbX - 2), y,
    trunc(thumbX + 2), y + Height - 1, AccentPale);

  if activeWidget = thisWidgetID then
    { dragging }
    colour := AccentDark
  else if hotWidget = thisWidgetID then
    { hovering }
    colour := AccentNormal
  else
    colour := AccentDark;

  Rect(
    trunc(thumbX - 2), y,
    trunc(thumbX + 2), y + Height - 1, colour)
end;

function SliderDrag(const x, y, width: smallint; var state: smallint; const minValue, maxValue: smallint): TSliderDragState;
var
  zone: TZone;
  thisWidgetID: smallint;
  perc, range: double;
  pendingValue, thumbX: smallint;
  colour: longword;
begin
  if minValue >= maxValue then
    PanicHalt('Slider: minValue has to be less than maxValue!');

  zone.x := x;
  zone.y := y;
  zone.width := width;
  zone.height := 5;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if pointInZone(GetMousePoint, zone) then begin
    hotWidget := thisWidgetID;

    if mouseJustPressed then
      activeWidget := thisWidgetID;
  end;

  { Value update logic }
  range := maxValue - minValue;
  if activeWidget = thisWidgetID then begin
    pendingValue := trunc(clamp(GetMouseX, x, x + width) - x);
    perc := pendingValue / width;
    state := round(perc * range)
  end;

  { Render logic }
  line(x, y + 2, x + width, y + 2, Black);

  perc := (state - minValue) / range;
  thumbX := round(x + perc * width);

  rectfill(trunc(thumbX - 2), trunc(zone.y), trunc(thumbX + 2), trunc(zone.y + 4), White);

  if activeWidget = thisWidgetID then
    { dragging }
    colour := AccentDark
  else if hotWidget = thisWidgetID then
    { hovering }
    colour := AccentNormal
  else
    colour := AccentDark;

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

  RectFill(
    x, y,
    x + width - 1, y + height - 1,
    AccentDark);

  RectFill(
    x, y,
    trunc(x + w) - 1, y + height - 1,
    AccentNormal);

  Rect(
    x, y,
    x + width - 1, y + height - 1,
    AccentPale);
end;

procedure ProgressBarLabelled(const x, y, width, height: smallint; const perc: double);
const
  MarginTop = 1;
var
  percStr: string;
  w: word;
begin
  GUIAssertFontSet;

  ProgressBar(x, y, width, height, perc);
  
  percStr := i32str(round(perc * 100)) + '%';
  w := GUIMeasureText(percStr);

  TextLabel(
    percStr,
    x + (width - w) div 2,
    y + MarginTop)
end;
{$endif}

end.
