unit ImmediateGUIPromptBox;

{$Mode TP}

interface

const
  TPromptResult = (PromptWait, PromptYes, PromptNo);

{ Prompt Box }
procedure setPromptBoxAssets(const background, btnNormal, btnHovered, btnPressed: longint);
function getPromptKey: integer;

procedure ShowPromptBox(const text: string; const key: integer);
function PromptButton(const text: string; const x, y: integer): boolean;
function PromptBox: TPromptResult;


implementation

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
  thisWidgetID := nextWidgetID;
  { PromptButton := ImageButton(x, y, imgPromptButtonNormal, imgPromptButtonNormal, imgPromptButtonPressed); }
  inc(nextWidgetID);

  if pointInZone(mousePoint, zone) then begin
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

