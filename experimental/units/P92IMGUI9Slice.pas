unit P92IMGUI9Slice;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses P92AssetHandles;

type
  TNineSliceMargins = record
    top, right, bottom, left: integer
  end;

procedure SprNineSlice(
  const texHandle: TTextureHandle;
  const x, y, width, height: integer;
  const margins: TNineSliceMargins
);

function ButtonNineSlice(
  const caption: string;
  const x, y: smallint;
  const margins: TNineSliceMargins;
  const texNormal, texHovered, texPressed: TTextureHandle
): boolean;


implementation

uses P92Panic, P92Tex, P92TexDraw, P92IMGUI, P92Geometry, P92AssetRegistry, P92Mouse;

procedure SprNineSlice(
  const texHandle: TTextureHandle;
  const x, y, width, height: integer;
  const margins: TNineSliceMargins
);
var
  srcCentreW, srcCentreH: integer;
  destCentreW, destCentreH: integer;
begin
  if not IsTexSet(texHandle) then
    PanicHalt('SprNineSlice: texHandle is unset ' + '!');

  srcCentreW := GetTexWidth(texHandle) - margins.left - margins.right;
  srcCentreH := GetTexHeight(texHandle) - margins.top - margins.bottom;
  destCentreW := width - margins.left - margins.right;
  destCentreH := height - margins.top - margins.bottom;

  { Middle fill }
  SprRegionStretch(texHandle,
    margins.left, margins.top, srcCentreW, srcCentreH,
    x + margins.left, y + margins.top, destCentreW, destCentreH);

  { Top side }
  SprRegionStretch(
    texHandle,
    margins.left, 0, srcCentreW, margins.top,
    x + margins.left, y, destCentreW, margins.top);

  { Bottom side }
  SprRegionStretch(
    texHandle,

    margins.left,
    GetTexHeight(texHandle) - margins.bottom,
    srcCentreW,
    margins.bottom,

    x + margins.left,
    y + height - margins.bottom,
    destCentreW,
    margins.bottom);

  { Left side }
  SprRegionStretch(
    texHandle,

    0, margins.top, margins.left, srcCentreH,
    x, y + margins.top, margins.left, destCentreH);

  { Right side }
  SprRegionStretch(
    texHandle,
    GetTexWidth(texHandle) - margins.right, margins.top, margins.right, srcCentreH,
    x + width - margins.right, y + margins.top, margins.right, destCentreH);

  { Corners }
  SprRegion(texHandle, 0, 0, margins.left, margins.top, x, y);
  SprRegion(texHandle, GetTexWidth(texHandle) - margins.right, 0, margins.right, margins.top, x + width - margins.right, y);
  SprRegion(texHandle, 0, GetTexHeight(texHandle) - margins.bottom, margins.left, margins.bottom, x, y + height - margins.bottom);
  SprRegion(texHandle, GetTexWidth(texHandle) - margins.right, GetTexHeight(texHandle) - margins.bottom, margins.right, margins.bottom, x + width - margins.right, y + height - margins.bottom);
end;


function ButtonNineSlice(
  const caption: string;
  const x, y: smallint;
  const margins: TNineSliceMargins;
  const texNormal, texHovered, texPressed: TTextureHandle
): boolean;
var
  zone: TZone;
  w: smallint;
  thisWidgetID: smallint;
  texHandle: TTextureHandle;
begin
  GUIAssertFontSet;

  zone.x := x;
  zone.y := y;
  zone.width := GUIMeasureText(caption) + margins.left + margins.right;
  zone.height := BorrowBMFontPtr(GetGUIActiveFontHandle)^.lineHeight + margins.top + margins.bottom;

  { Update logic }
  thisWidgetID := GetNextWidgetID;
  IncNextWidgetID;

  if PointInZone(GetMousePoint, zone) then begin
    SetHotWidget(thisWidgetID);

    if GetMouseJustPressed then SetActiveWidget(thisWidgetID);
  end;

  { Render logic }
  if GetActiveWidget = thisWidgetID then
    texHandle := texPressed
  else if GetHotWidget = thisWidgetID then
    texHandle := texHovered
  else
    texHandle := texNormal;

  { Spr(texHandle, x, y); }
  SprNineSlice(texHandle, x, y, trunc(zone.width), trunc(zone.height), margins);

  TextLabel(caption, x + margins.left, y + margins.top);

  if GetMouseJustReleased and (GetHotWidget = thisWidgetID) and (GetActiveWidget = thisWidgetID) then
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    ButtonNineSlice := true
  else
    ButtonNineSlice := false;
end;

end.
