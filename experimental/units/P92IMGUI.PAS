{
  Immediate Mode GUI unit
  Part of Posit-92 game engine
  By Hevanafa
}

unit P92IMGUI;

{$Mode ObjFPC}
{$H+}{$J-}

interface

{$ifdef P92_IMGUI}
uses
  P92AssetHandles, P92BMFont, P92Geometry;

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

procedure Checkbox(const caption: string; const x, y: smallint; var state: TCheckboxState);

procedure Slider(const x, y, width: smallint; var state: TSliderState; const minValue, maxValue: smallint);
function SliderDrag(const x, y, width: smallint; var state: TSliderState; const minValue, maxValue: smallint): TSliderDragState;

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
    buttonColour := IceCreamRed
  else if hotWidget = thisWidgetID then
    buttonColour := IceCreamOrange
  else 
    buttonColour := IceCreamWhite;

  rectfill(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), buttonColour);
  rect(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), IceCreamWhite);
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

  { if (items = nil) or (items.count = 0) then exit; }
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
  fontPtr: PBMFont;
  zone: TZone;
  w: smallint;
  thisWidgetID: smallint;
  checkboxColour: longword;
begin
  GUIAssertFontSet;

  fontPtr := BorrowBMFontPtr(activeFontHandle);

  zone.x := x;
  zone.y := y;

  w := GUIMeasureText(caption);
  zone.width := w + 6;
  zone.height := fontPtr^.lineHeight;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if PointInZone(GetMousePoint, zone) then begin
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
  if minValue >= maxValue then
    PanicHalt('Slider: minValue has to be less than maxValue!');

  zone.x := x;
  zone.y := y;
  zone.width := width;
  zone.height := 5;

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
    pendingValue := trunc(clamp(GetMouseX, x, x + width) - x);
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
  GUIAssertFontSet;

  ProgressBar(x, y, width, height, perc);
  
  percStr := i32str(round(perc * 100)) + '%';
  w := measureBMFont(activeFontHandle, percStr);

  TextLabel(
    percStr,
    x + (width - w) div 2,
    y + (height - BorrowBMFontPtr(activeFontHandle)^.lineHeight) div 2);
end;
{$endif}

end.
