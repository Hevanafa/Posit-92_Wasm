unit ImmediateGUIPromptBox;

{$Mode ObjFPC}
{$H+}{$J-}

interface

type
  TPromptResult = (PromptWait, PromptYes, PromptNo);

procedure setClickConsumed(const value: boolean);
procedure setPromptBoxAssets(const background, btnNormal, btnHovered, btnPressed: longint);
function getPromptKey: integer;
function allowWidgetInteraction: boolean;

procedure ShowPromptBox(const text: string; const key: integer);

function UnderButton(const caption: string; const x, y, width, height: smallint): boolean;
function UnderImageButton(const x, y: smallint; const imgNormal, imgHovered, imgPressed: longint): boolean;

function PromptButton(const text: string; const x, y: integer): boolean;
function PromptBox: TPromptResult;


implementation

uses
  Graphics, Shapes,
  ImmediateGUI,
  ImgRef, ImgRefFast, VGA;

const
  SemitransparentBlack = $80000000;

var
  { Prompt box assets }
  imgPromptBG, imgPromptButtonNormal, imgPromptButtonHovered, imgPromptButtonPressed: longint;

  { Prompt box variables }
  isPromptShown: boolean;
  promptKey: smallint;  { Use Prompts enum }
  promptText: string;
  clickConsumed: boolean;


procedure setClickConsumed(const value: boolean);
begin
  clickConsumed := value
end;

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

function allowWidgetInteraction: boolean;
begin
  allowWidgetInteraction := (not isPromptShown)
end;


{ Show prompt box }
procedure ShowPromptBox(const text: string; const key: integer);
begin
  isPromptShown := true;
  promptKey := key;
  promptText := text;
end;

function UnderButton(const caption: string; const x, y, width, height: smallint): boolean;
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
  thisWidgetID := getNextWidgetID;
  incNextWidgetID;

  if allowWidgetInteraction then begin
    if pointInZone(getMousePoint, zone) then begin
      setHotWidget(thisWidgetID);

      if getMouseJustPressed then setActiveWidget(thisWidgetID);
    end;
  end;

  { Render logic }
  if getActiveWidget = thisWidgetID then
    buttonColour := IceCreamRed
  else if getHotWidget = thisWidgetID then
    buttonColour := IceCreamOrange
  else
    buttonColour := IceCreamWhite;

  rectfill(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), buttonColour);
  rect(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), IceCreamWhite);
  TextLabel(caption, trunc(zone.x + 4), trunc(zone.y + 4));

  if getMouseJustReleased and (getHotWidget = thisWidgetID) and (getActiveWidget = thisWidgetID) then begin
    { activeWidget = -1 }  { Index reset is handled at the end of draw }

    if not clickConsumed then begin
      UnderButton := true;
      clickConsumed := true
    end else
      UnderButton := false;
  end else
    UnderButton := false;
end;

function UnderImageButton(const x, y: smallint; const imgNormal, imgHovered, imgPressed: longint): boolean;
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
  thisWidgetID := getNextWidgetID;
  incNextWidgetID;

  if allowWidgetInteraction then begin
    if pointInZone(getMousePoint, zone) then begin
      setHotWidget(thisWidgetID);

      if getMouseJustPressed then setActiveWidget(thisWidgetID);
    end;
  end;

  { Render logic }
  if getActiveWidget = thisWidgetID then
    buttonImgHandle := imgPressed
  else if getHotWidget = thisWidgetID then
    buttonImgHandle := imgHovered
  else
    buttonImgHandle := imgNormal;

  spr(buttonImgHandle, x, y);
  { Use this in case you want your buttons have semitransparent pixels }
  { sprBlend(buttonImgHandle, x, y); }

  if getMouseJustReleased and (getHotWidget = thisWidgetID) and (getActiveWidget = thisWidgetID) then
    { activeWidget = -1 }  { Index reset is handled at the end of draw }

    if not clickConsumed then begin
      UnderImageButton := true;
      clickConsumed := true
    end else
      UnderImageButton := false
  else
    UnderImageButton := false;
end;

function PromptButton(const text: string; const x, y: integer): boolean;
var
  zone: TZone;
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
  thisWidgetID := getNextWidgetID;
  { PromptButton := ImageButton(x, y, imgPromptButtonNormal, imgPromptButtonNormal, imgPromptButtonPressed); }
  incNextWidgetID;

  if pointInZone(getMousePoint, zone) then begin
    setHotWidget(thisWidgetID);
    if getMouseJustPressed then setActiveWidget(thisWidgetID);
  end;

  { Render logic }
  if getActiveWidget = thisWidgetID then
    buttonImgHandle := imgPromptButtonPressed
  else if getHotWidget = thisWidgetID then
    buttonImgHandle := imgPromptButtonHovered
  else
    buttonImgHandle := imgPromptButtonNormal;

  spr(buttonImgHandle, x, y);

  textWidth := guiMeasureText(text);
  w := getImageWidth(imgPromptButtonNormal);
  h := getImageHeight(imgPromptButtonPressed);

  textX := x + (w - textWidth) div 2;
  textY := y + (h - getActiveFont^.lineHeight) div 2;

  { when pressed }
  if getActiveWidget = thisWidgetID then
    inc(textY);

  TextLabel(text, textX, textY);

  if getMouseJustReleased and (getHotWidget = thisWidgetID) and (getActiveWidget = thisWidgetID) then begin
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
  if not isPromptShown then begin
    PromptBox := PromptNo;
    exit
  end;

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

