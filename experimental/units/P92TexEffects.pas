unit P92TexEffects;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }

interface

procedure SprOutline(const texHandle: longint; const x, y: smallint; const colour: longword);
{ This procedure only processes solid pixels }
procedure SprShadow(const texHandle: longint; const x, y: smallint; const offsetX, offsetY: smallint; const colour: longword);
{ Replaces 1 colour of a texture, in-place }
procedure ReplaceColour(const texHandle: longint; const oldColour, newColour: longword);


implementation

uses P92Tex, P92TexDraw, P92VGA;

procedure SprOutline(const texHandle: longint; const x, y: smallint; const colour: longword);
var
  a, b: smallint;
  texture: PSoftwareTex;
begin
  if not IsTextureSet(texHandle) then exit;

  texture := BorrowTexturePtr(texHandle);

  { Within sprite bounds }
  for b:=0 to texture^.height - 1 do
    for a:=0 to texture^.width - 1 do begin
      { Skip this solid pixel }
      if unsafeSprGetAlpha(texture, a, b) > 0 then continue;

      { Check 4 neighbours }
      if (b - 1 >= 0) and (unsafeSprGetAlpha(texture, a, b - 1) > 0)
        or (b + 1 < texture^.height) and (unsafeSprGetAlpha(texture, a, b + 1) > 0)
        or (a - 1 >= 0) and (unsafeSprGetAlpha(texture, a - 1, b) > 0)
        or (a + 1 < texture^.width) and (unsafeSprGetAlpha(texture, a + 1, b) > 0) then
        pset(x + a, y + b, colour);
    end;
  
  { Padding area }
  { top & bottom }
  for a:=0 to texture^.width - 1 do begin
    if unsafeSprGetAlpha(texture, a, 0) > 0 then
      pset(x + a, y - 1, colour);

    if unsafeSprGetAlpha(texture, a, texture^.height - 1) > 0 then
      pset(x + a, y + texture^.height, colour);
  end;

  { left & right }
  for b:=0 to texture^.height - 1 do begin
    if unsafeSprGetAlpha(texture, 0, b) > 0 then
      pset(x - 1, y + b, colour);

    if unsafeSprGetAlpha(texture, texture^.width - 1, b) > 0 then
      pset(x + texture^.width, y + b, colour);
  end;

  spr(texHandle, x, y)
end;


procedure SprShadow(const texHandle: longint; const x, y: smallint; const offsetX, offsetY: smallint; const colour: longword);
var
  a, b: smallint;
  destX, destY: smallint;
  texture: PSoftwareTex;
  alpha: byte;
begin
  if not IsTextureSet(texHandle) then exit;

  texture := BorrowTexturePtr(texHandle);

  alpha := colour shr 24 and $FF;
  if alpha = 0 then exit;

  for b:=0 to texture^.height - 1 do
  for a:=0 to texture^.width - 1 do begin
    if unsafeSprGetAlpha(texture, a, b) < 255 then continue;

    destX := x + a + offsetX;
    destY := y + b + offsetY;

    if (destX < clipX1) or (destX > clipX2)
      or (destY < clipY1) or (destY > clipY2) then continue;

    if alpha = 255 then
      unsafePset(destX, destY, colour)
    else
      unsafePsetBlend(destX, destY, colour);
  end;
  
  spr(texHandle, x, y)
end;

procedure ReplaceColour(const texHandle: longint; const oldColour, newColour: longword);
var
  a, b: word;
  texture: PSoftwareTex;
begin
  if not IsTextureSet(texHandle) then exit;

  texture := BorrowTexturePtr(texHandle);

  for b:=0 to texture^.height - 1 do
  for a:=0 to texture^.width - 1 do
    if unsafeSprPget(texture, a, b) = oldColour then
      unsafeSprPset(texture, a, b, newColour);
end;

end.
