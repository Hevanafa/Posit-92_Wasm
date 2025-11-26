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
  TPromptResult = (PromptWait, PromptYes, PromptNo);

  TListViewState = record
    x, y: integer;
    selectedIndex: integer;
  end;

procedure initImmediateGUI;

function getHotWidget: integer;
function getActiveWidget: integer;
function getNextWidgetID: integer;

{ Can be used with drawMouse }
function hasHoveredWidget: boolean;

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

{ Widgets }
procedure TextLabel(const text: string; const x, y: integer);

function Button(const caption: string; const x, y, width, height: integer): boolean;
function ImageButton(const x, y: integer; const imgNormal, imgHovered, imgPressed: longint): boolean;

procedure ListView(const items: array of string; var state: TListViewState);

procedure Checkbox(const caption: string; const x, y: integer; var state: TCheckboxState);
procedure Slider(const x, y, width: integer; var state: TSliderState; const minValue, maxValue: integer);

procedure ProgressBar(const x, y, width, height: integer; const perc: double);
procedure ProgressBarLabelled(const x, y, width, height: integer; const perc: double);

{ Prompt Box }
procedure setPromptBoxAssets(const background, btnNormal, btnHovered, btnPressed: longint);
function getPromptKey: integer;

procedure ShowPromptBox(const text: string; const key: integer);
function PromptButton(const text: string; const x, y: integer): boolean;
function PromptBox: TPromptResult;


implementation

uses
  Conv, Bitmap, Graphics, Maths,
  Mouse, Panic, Shapes, VGA;

const
  Black = $FF000000;
  White = $FFFFFFFF;
  Red = $FFFF5555;
  DarkBlue = $FF0000AA;
  SemitransparentBlack = $80000000;

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

  { Prompt box assets }
  imgPromptBG, imgPromptButtonNormal, imgPromptButtonHovered, imgPromptButtonPressed: longint;

  { Prompt box variables }
  isPromptShown: boolean;
  promptKey: integer;  { Use Prompts enum }
  promptText: string;
  clickConsumed: boolean;


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

function getHotWidget: integer;
begin
  getHotWidget := hotWidget
end;

function getActiveWidget: integer;
begin
  getActiveWidget := activeWidget
end;

function getNextWidgetID: integer;
begin
  getNextWidgetID := nextWidgetID
end;

function hasHoveredWidget: boolean;
begin
  hasHoveredWidget := hotWidget > -1
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

  { Used by prompt box }
  clickConsumed := false;
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

procedure assertImageSet(const varName: string; const imgHandle: longint);
begin
  if not isImageSet(imgHandle) then
    panicHalt(varName + ' is unset!');
end;

function guiMeasureText(const text: string): word;
begin
  assertFontSet;
  guiMeasureText := measureBMFont(text, activeFontGlyphs)
end;


{ Begin widgets }

function allowWidgetInteraction: boolean;
begin
  allowWidgetInteraction := (not isPromptShown)
end;

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
  inc(nextWidgetID);

  if allowWidgetInteraction then begin
    if rectIntersects(zone, mouseZone) then begin
      hotWidget := thisWidgetID;

      if mouseJustPressed then activeWidget := thisWidgetID;
    end;
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

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then begin
    { activeWidget = -1 }  { Index reset is handled at the end of draw }

    if not clickConsumed then begin
      Button := true;
      clickConsumed := true
    end else
      Button := false;
  end else
    Button := false;
end;

function ImageButton(const x, y: integer; const imgNormal, imgHovered, imgPressed: longint): boolean;
var
  zone: TRect;
  thisWidgetID: integer;
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

  if allowWidgetInteraction then begin
    if rectIntersects(zone, mouseZone) then begin
      hotWidget := thisWidgetID;

      if mouseJustPressed then activeWidget := thisWidgetID;
    end;
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

    if not clickConsumed then begin
      ImageButton := true;
      clickConsumed := true
    end else
      ImageButton := false
  else
    ImageButton := false;
end;

procedure ListView(const items: array of string; var state: TListViewState);
var
  a: word;
  lineHeight: word;
  widgetWidth, widgetHeight: word;
  thisWidgetID: integer;
  zone: TRect;
  clickedIndex: integer;
begin
  assertFontSet;

  lineHeight := activeFont.lineHeight + 2;
  widgetWidth := 100;
  widgetHeight := lineHeight * (high(items) + 1);

  zone.x := state.x;
  zone.y := state.y;
  zone.width := widgetWidth;
  zone.height := widgetHeight;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if allowWidgetInteraction then
    if rectIntersects(zone, mouseZone) then begin
      hotWidget := thisWidgetID;

      if mouseJustPressed then begin
        activeWidget := thisWidgetID;

        { Calculate which item was clicked }
        clickedIndex := (mouseY - state.y) div lineHeight;
        if clickedIndex in [0..high(items)] then
          state.selectedIndex := clickedIndex;
      end;
    end;

  { Update Render logic }
  rectfill(state.x, state.y, state.x + widgetWidth, state.y + widgetHeight, Black);

  rectfill(
    state.x, state.y + lineHeight * state.selectedIndex,
    state.x + widgetWidth, state.y + lineHeight * (state.selectedIndex + 1), Red);

  for a := 0 to high(items) do
    TextLabel(
      items[a],
      state.x + 2, state.y + 2 + lineHeight * a);

  rect(state.x, state.y, state.x + widgetWidth, state.y + widgetHeight, White);
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

  w := guiMeasureText(caption);
  zone.width := w + 6;
  zone.height := activeFont.lineHeight;

  { Update logic }
  thisWidgetID := nextWidgetID;
  inc(nextWidgetID);

  if allowWidgetInteraction then begin
    if rectIntersects(zone, mouseZone) then begin
      hotWidget := thisWidgetID;

      if mouseJustPressed then activeWidget := thisWidgetID;
    end;
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
    if not clickConsumed then begin
      state.checked := not state.checked;
      clickConsumed := true
    end;
  end;
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

  if allowWidgetInteraction then begin
    if rectIntersects(zone, mouseZone) then begin
      hotWidget := thisWidgetID;

      if mouseJustPressed then activeWidget := thisWidgetID;
    end;
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


procedure ProgressBar(const x, y, width, height: integer; const perc: double);
var
  w: word;
begin
  w := trunc(clamp(perc, 0.0, 1.0) * width);

  rectfill(x, y, x + width, y + height, black);
  rectfill(x, y, trunc(x + w), y + height, red);
  rect(x, y, x + width, y + height, white);
end;

procedure ProgressBarLabelled(const x, y, width, height: integer; const perc: double);
var
  percStr: string;
  w: word;
begin
  assertFontSet;

  ProgressBar(x, y, width, height, perc);
  
  percStr := i32str(round(perc * 100)) + '%';
  w := measureBMFont(percStr, activeFontGlyphs);
  TextLabel(percStr, x + (width - w) div 2, y + (height - activeFont.lineHeight) div 2);
end;


{ Prompt Box }
procedure setPromptBoxAssets(const background, btnNormal, btnHovered, btnPressed: longint);
begin
  imgPromptBG := background;
  imgPromptButtonNormal := btnNormal;
  imgPromptButtonHovered := btnHovered;
  imgPromptButtonPressed := btnPressed;
end;

function getPromptKey: integer;
begin
  getPromptKey := promptKey
end;

{ Show prompt box }
procedure ShowPromptBox(const text: string; const key: integer);
begin
  isPromptShown := true;
  promptKey := key;
  promptText := text;
end;

function PromptButton(const text: string; const x, y: integer): boolean;
var
  zone: TRect;
  thisWidgetID: integer;
  buttonImgHandle: longword;

  textWidth: word;
  w, h: word;
  textX, textY: integer;
begin
  assertImageSet('imgPromptButtonNormal', imgPromptButtonNormal);
  assertImageSet('imgPromptButtonHovered', imgPromptButtonHovered);
  assertImageSet('imgPromptButtonPressed', imgPromptButtonPressed);

  zone.x := x;
  zone.y := y;
  zone.width := getImageWidth(imgPromptButtonNormal);
  zone.height := getImageHeight(imgPromptButtonNormal);

  { Update logic }
  thisWidgetID := nextWidgetID;
  { PromptButton := ImageButton(x, y, imgPromptButtonNormal, imgPromptButtonNormal, imgPromptButtonPressed); }
  inc(nextWidgetID);

  if rectIntersects(zone, mouseZone) then begin
    hotWidget := thisWidgetID;
    if mouseJustPressed then activeWidget := thisWidgetID;
  end;

  { Render logic }
  if activeWidget = thisWidgetID then
    buttonImgHandle := imgPromptButtonPressed
  else if hotWidget = thisWidgetID then
    buttonImgHandle := imgPromptButtonHovered
  else 
    buttonImgHandle := imgPromptButtonNormal;

  spr(buttonImgHandle, x, y);

  textWidth := guiMeasureText(text);
  w := getImageWidth(imgPromptButtonNormal);
  h := getImageHeight(imgPromptButtonPressed);

  textX := x + (w - textWidth) div 2;
  textY := y + (h - activeFont.lineHeight) div 2;

  { when pressed }
  if getActiveWidget = thisWidgetID then
    inc(textY);

  TextLabel(text, textX, textY);

  if mouseJustReleased and (hotWidget = thisWidgetID) and (activeWidget = thisWidgetID) then begin
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    if not clickConsumed then begin
      PromptButton := true;
      clickConsumed := true
    end else
      PromptButton := false;
  end else
    PromptButton := false;
end;

{ Prompt box render logic }
function PromptBox: TPromptResult;
const
  top = 60;
  left = 100;
var
  w: word;
begin
  if not isPromptShown then exit;

  assertImageSet('imgPromptBG', imgPromptBG);

  clsBlend(SemitransparentBlack);

  spr(imgPromptBG, left, top);

  w := guiMeasureText(promptText);
  TextLabel(promptText, (vgaWidth - w) div 2, 90);

  PromptBox := PromptWait;

  if PromptButton('Yes', 160 - 40, 110) then begin
    isPromptShown := false;
    PromptBox := PromptYes
  end;

  if PromptButton('No', 160 + 10, 110) then begin
    isPromptShown := false;
    PromptBox := PromptNo
  end;
end;


end.
