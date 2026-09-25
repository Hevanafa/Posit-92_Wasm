{
  Prompt Box widget for the Immediate Mode GUI unit
  Part of Posit-92 game engine
  By Hevanafa
}

unit P92IMGUIPromptBox;

{$Mode ObjFPC}
{$H+}{$J-}

interface

{$IFDEF P92_IMGUI}

uses
  P92AssetHandles;

type
  TPromptResult = (
    PromptResultWait,
    PromptResultYes,
    PromptResultNo
  );

procedure SetClickConsumed(const value: boolean);
procedure SetPromptBoxAssets(const background, btnNormal, btnHovered, btnPressed: TTextureHandle);
function GetPromptKey: string;
function AllowWidgetInteraction: boolean;

procedure ShowPromptBox(const text: string; const key: string);

function UnderButtonSized(const caption: string; const x, y, width, height: smallint): boolean;
function UnderImageButton(const x, y: smallint; const texNormal, texHovered, texPressed: TTextureHandle): boolean;

function PromptButton(const text: string; const x, y: smallint): boolean;
function PromptBox: TPromptResult;

{$ENDIF}

implementation

{$IFDEF P92_IMGUI}

uses
  P92Graphics, P92Geometry, P92Mouse,
  P92IMGUI, P92AssetRegistry,
  P92Tex, P92TexDraw, P92BMFont, P92VGA;

const
  SemitransparentBlack = $80000000;

var
  { Prompt box assets }
  texPromptBG,
  texPromptButtonNormal, texPromptButtonHovered, texPromptButtonPressed: TTextureHandle;

  { Prompt box variables }
  isPromptShown: boolean;
  promptKey: string;
  promptText: string;
  clickConsumed: boolean;


procedure SetClickConsumed(const value: boolean);
begin
  clickConsumed := value
end;

procedure SetPromptBoxAssets(const background, btnNormal, btnHovered, btnPressed: TTextureHandle);
begin
  texPromptBG := background;
  texPromptButtonNormal := btnNormal;
  texPromptButtonHovered := btnHovered;
  texPromptButtonPressed := btnPressed;
end;

function GetPromptKey: string;
begin
  GetPromptKey := promptKey
end;

function AllowWidgetInteraction: boolean;
begin
  AllowWidgetInteraction := (not isPromptShown)
end;


{ Show prompt box }
procedure ShowPromptBox(const text: string; const key: string);
begin
  isPromptShown := true;
  promptKey := key;
  promptText := text;
end;

function UnderButtonSized(const caption: string; const x, y, width, height: smallint): boolean;
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
  thisWidgetID := getNextWidgetID;
  incNextWidgetID;

  if AllowWidgetInteraction then begin
    if pointInZone(GetMousePoint, zone) then begin
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
      UnderButtonSized := true;
      clickConsumed := true
    end else
      UnderButtonSized := false;
  end else
    UnderButtonSized := false;
end;

function UnderImageButton(
  const x, y: smallint;
  const texNormal, texHovered, texPressed: TTextureHandle
): boolean;
var
  zone: TZone;
  texturePtr: PSoftwareTex;
  thisWidgetID: smallint;
  buttonImgHandle: longword;
begin
  GUIAssertFontSet;

  texturePtr := BorrowTexPtr(texNormal);

  zone.x := x;
  zone.y := y;
  zone.width := texturePtr^.width;
  zone.height := texturePtr^.height;

  { Update logic }
  thisWidgetID := getNextWidgetID;
  incNextWidgetID;

  if AllowWidgetInteraction then begin
    if pointInZone(getMousePoint, zone) then begin
      setHotWidget(thisWidgetID);

      if getMouseJustPressed then setActiveWidget(thisWidgetID);
    end;
  end;

  { Render logic }
  if getActiveWidget = thisWidgetID then
    buttonImgHandle := texPressed
  else if getHotWidget = thisWidgetID then
    buttonImgHandle := texHovered
  else
    buttonImgHandle := texNormal;

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

function PromptButton(const text: string; const x, y: smallint): boolean;
var
  zone: TZone;
  thisWidgetID: smallint;

  buttonImgHandle: longword;
  texturePtr: PSoftwareTex;
  fontPtr: PBMFont;

  textWidth: word;
  w, h: word;
  textX, textY: smallint;
begin
  AssertTexSet('imgPromptButtonNormal', texPromptButtonNormal);
  AssertTexSet('imgPromptButtonHovered', texPromptButtonHovered);
  AssertTexSet('imgPromptButtonPressed', texPromptButtonPressed);

  texturePtr := BorrowTexPtr(texPromptButtonNormal);

  zone.x := x;
  zone.y := y;
  zone.width := texturePtr^.width;
  zone.height := texturePtr^.height;

  { Update logic }
  thisWidgetID := getNextWidgetID;
  { PromptButton := ImageButton(x, y, texPromptButtonNormal, texPromptButtonNormal, texPromptButtonPressed); }
  incNextWidgetID;

  if pointInZone(getMousePoint, zone) then begin
    setHotWidget(thisWidgetID);
    if getMouseJustPressed then setActiveWidget(thisWidgetID);
  end;

  { Render logic }
  if getActiveWidget = thisWidgetID then
    buttonImgHandle := texPromptButtonPressed
  else if getHotWidget = thisWidgetID then
    buttonImgHandle := texPromptButtonHovered
  else
    buttonImgHandle := texPromptButtonNormal;

  spr(buttonImgHandle, x, y);

  textWidth := GUIMeasureText(text);
  w := texturePtr^.width;
  h := texturePtr^.height;

  fontPtr := BorrowBMFontPtr(GetGUIActiveFontHandle);

  textX := x + (w - textWidth) div 2;
  textY := y + (h - fontPtr^.lineHeight) div 2;

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
    PromptBox := PromptResultNo;
    exit
  end;

  AssertTexSet('imgPromptBG', texPromptBG);

  clsBlend(SemitransparentBlack);

  spr(texPromptBG, left, top);

  w := GUIMeasureText(promptText);
  TextLabel(promptText, (vgaWidth - w) div 2, 90);

  PromptBox := PromptResultWait;

  if PromptButton('Yes', 160 - 40, 110) then begin
    isPromptShown := false;
    PromptBox := PromptResultYes
  end;

  if PromptButton('No', 160 + 10, 110) then begin
    isPromptShown := false;
    PromptBox := PromptResultNo
  end;
end;

{$ENDIF}

end.

