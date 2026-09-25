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


implementation

uses P92Panic, P92Tex, P92TexDraw;

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
begin
  { TODO: Implement this }
end;

end.
