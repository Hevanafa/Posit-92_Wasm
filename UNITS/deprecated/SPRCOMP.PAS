{
  SprComp unit
  Part of Posit-92 framework
  By Hevanafa, 26-11-2025

  An extension of Bitmap unit to handle alpha compositing
  Deprecated in favour of ImgRefComp
}

unit SprComp;

interface

procedure sprAlpha(const imgHandle: longint; const x, y: integer; opacity: double);
procedure sprBlend(const imgHandle: longint; const x, y: integer);
procedure sprRegionBlend(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);


implementation

uses Bitmap, Maths, VGA;

procedure sprAlpha(const imgHandle: longint; const x, y: integer; opacity: double);
var
  image: PBitmap;
  px, py: integer;
  colour: longword;
  alpha: byte;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);
  opacity := clamp(opacity, 0.0, 1.0);

  for py := 0 to image^.height - 1 do
  for px := 0 to image^.width - 1 do begin
    if (x + px >= vgaWidth) or (x + px < 0)
      or (y + py >= vgaHeight) or (y + py < 0) then continue;

    colour := unsafeSprPget(image, px, py);
    alpha := colour shr 24;
    if alpha = 0 then continue;
    
    alpha := trunc(alpha * opacity);
    colour := (colour and $FFFFFF) or (alpha shl 24);

    unsafePsetBlend(x + px, y + py, colour)
  end;
end;

procedure sprBlend(const imgHandle: longint; const x, y: integer);
var
  image: PBitmap;
  px, py: integer;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for py := 0 to image^.height - 1 do
  for px := 0 to image^.width - 1 do begin
    if (x + px >= vgaWidth) or (x + px < 0)
      or (y + py >= vgaHeight) or (y + py < 0) then continue;

    colour := unsafeSprPget(image, px, py);
    psetBlend(x + px, y + py, colour)
  end;
end;

procedure sprRegionBlend(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);
var
  px, py: integer;
  colour: longword;
  image: PBitmap;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for py := 0 to srcH - 1 do
  for px := 0 to srcW - 1 do begin
    if (destX + px >= vgaWidth) or (destX + px < 0)
      or (destY + py >= vgaHeight) or (destY + py < 0) then continue;

    colour := unsafeSprPget(image, srcX + px, srcY + py);
    psetBlend(destX + px, destY + py, colour)
  end;
end;

end.