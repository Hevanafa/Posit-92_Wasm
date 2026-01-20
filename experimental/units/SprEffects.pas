unit SprEffects;

{$Mode TP}
{$B-}

interface

procedure sprOutline(const imgHandle: longint; const x, y: integer; const colour: longword);
procedure sprShadow(const imgHandle: longint; const x, y: integer; const offsetX, offsetY: integer; const colour: longword);
procedure replaceColour(const imgHandle: longint; const oldColour, newColour: longword);


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


{ This procedure only processes solid pixels }
procedure sprShadow(const imgHandle: longint; const x, y: integer; const offsetX, offsetY: integer; const colour: longword);
var
  a, b: integer;
  destX, destY: integer;
  image: PImageRef;
  alpha: byte;
begin
  if not isImageSet(imgHandle) then exit;
  image := getImagePtr(imgHandle);

  alpha := colour shr 24 and $FF;
  if alpha = 0 then exit;

  for b:=0 to image^.height - 1 do
  for a:=0 to image^.width - 1 do begin
    if unsafeSprGetAlpha(image, a, b) < 255 then continue;

    destX := x + a + offsetX;
    destY := y + b + offsetY;

    if (destX < 0) or (destX >= vgaWidth)
      or (destY < 0) or (destY >= vgaHeight) then continue;

    if alpha = 255 then
      unsafePset(destX, destY, colour)
    else
      unsafePsetBlend(destX, destY, colour);
  end;
  
  spr(imgHandle, x, y)
end;

procedure replaceColour(const imgHandle: longint; const oldColour, newColour: longword);
var
  a, b: word;
  image: PImageRef;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for b:=0 to image^.height - 1 do
  for a:=0 to image^.width - 1 do
    if unsafeSprPget(image, a, b) = oldColour then
      unsafeSprPset(image, a, b, newColour);
end;


end.