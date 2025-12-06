unit SprEffects;

{$Mode TP}
{$B-}

interface

procedure sprOutline(const imgHandle: longint; const x, y: integer; const colour: longword);
procedure sprShadow(const imgHandle: longint; const x, y: integer; const offsetX, offsetY: integer; const colour: longword);


implementation

uses ImgRef, ImgRefFast, VGA;

procedure sprOutline(const imgHandle: longint; const x, y: integer; const colour: longword);
var
  a, b: integer;
  image: PImageRef;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  { Within sprite bounds }
  for b:=0 to image^.height - 1 do
    for a:=0 to image^.width - 1 do begin
      { Skip this solid pixel }
      if unsafeSprGetAlpha(image, a, b) > 0 then continue;

      { Check 4 neighbours }
      if (b - 1 >= 0) and (unsafeSprGetAlpha(image, a, b - 1) > 0)
        or (b + 1 < image^.height) and (unsafeSprGetAlpha(image, a, b + 1) > 0)
        or (a - 1 >= 0) and (unsafeSprGetAlpha(image, a - 1, b) > 0)
        or (a + 1 < image^.width) and (unsafeSprGetAlpha(image, a + 1, b) > 0) then
        pset(x + a, y + b, colour);
    end;
  
  { Padding area }
  { top & bottom }
  for a:=0 to image^.width - 1 do begin
    if unsafeSprGetAlpha(image, a, 0) > 0 then
      pset(x + a, y - 1, colour);

    if unsafeSprGetAlpha(image, a, image^.height - 1) > 0 then
      pset(x + a, y + image^.height, colour);
  end;

  { left & right }
  for b:=0 to image^.height - 1 do begin
    if unsafeSprGetAlpha(image, 0, b) > 0 then
      pset(x - 1, y + b, colour);

    if unsafeSprGetAlpha(image, image^.width - 1, b) > 0 then
      pset(x + image^.width, y + b, colour);
  end;

  spr(imgHandle, x, y)
end;


procedure sprShadow(const imgHandle: longint; const x, y: integer; const offsetX, offsetY: integer; const colour: longword);
var
  a, b: integer;
  image: PImageRef;
begin
  if not isImageSet(imgHandle) then exit;
  image := getImagePtr(imgHandle);

  for b:=0 to image^.height - 1 do
  for a:=0 to image^.width - 1 do begin
    if unsafeSprGetAlpha(image, a, b) < 255 then continue;

    if (x + a + offsetX < 0) or (x + a + offsetX >= vgaWidth)
      or (y + b + offsetY < 0) or (y + b + offsetY >= vgaHeight) then continue;

    unsafePset(x + a + offsetX, y + b + offsetY, colour)
  end;
  
  spr(imgHandle, x, y)
end;


end.