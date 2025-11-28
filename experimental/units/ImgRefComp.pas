unit ImgRefComp;

interface

{ Based on SprComp unit }
procedure sprAlpha(const imgHandle: longint; const x, y: integer; opacity: double);
procedure sprBlend(const imgHandle: longint; const x, y: integer);


implementation

procedure sprAlpha(const imgHandle: longint; const x, y: integer; opacity: double);
var
  image: PImageRef;
  px, py: integer;
  colour: longword;
  alpha: byte;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImageRefPtr(imgHandle);
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
  image: PImageRef;
  px, py: integer;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImageRefPtr(imgHandle);

  for py := 0 to image^.height - 1 do
  for px := 0 to image^.width - 1 do begin
    if (x + px >= vgaWidth) or (x + px < 0)
      or (y + py >= vgaHeight) or (y + py < 0) then continue;

    colour := unsafeSprPget(image, px, py);
    psetBlend(x + px, y + py, colour)
  end;
end;

end.