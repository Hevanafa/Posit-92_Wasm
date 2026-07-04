{ 
  SoftwareTexDraw unit
  Part of Posit-92 game engine
  By Hevanafa

  The term "texture" used in this unit is strictly in the context of CPU rendering
}

unit SoftwareTexDraw;

{$Mode ObjFPC}
{$H+}{$J-}
{$B-}  { Enable boolean short-circuiting }
{$R-}  { Turn off range checks }
{$Q-}  { Turn off overflow checks }

interface

procedure Spr(const texHandle: longint; const x, y: smallint);

procedure SprClear(const texHandle: longint; const colour: longword);

procedure SprRegion(
  const texHandle: longint;
  const srcX, srcY, srcW, srcH: smallint;
  const destX, destY: smallint);

procedure SprStretch(
  const texHandle: longint;
  const destX, destY, destWidth, destHeight: smallint);

procedure SprRegionStretch(
  const texHandle: longint;
  const srcX, srcY, srcWidth, srcHeight: smallint;
  const destX, destY, destWidth, destHeight: smallint);

procedure SprRegionSolid(
  const texHandle: longint;
  const srcX, srcY, srcW, srcH: smallint;
  const destX, destY: smallint;
  const colour: longword);

procedure SprFlip(const texHandle: longint; const x, y: smallint; const flip: smallint);

{ rotation is in radians }
procedure SprRotate(const texHandle: longint; const cx, cy: smallint; const rotation: double);

procedure SprToDest(const src, dest: longint; const x, y: smallint);

procedure SprRegionToDest(
  const src, dest: longint;
  const srcX, srcY, srcW, srcH: smallint;
  const destX, destY: smallint);

procedure SprFlipInPlace(const texHandle: longint; const flip: smallint);


implementation

uses
  P92Logger, P92Conversions, SoftwareTex, P92Maths, P92Panic, VGA;

procedure Spr(const texHandle: longint; const x, y: smallint);
var
  texture: PSoftwareTex;
  px, py: smallint;
  offset: longword;
  alpha: byte;
  colour: longword;
begin
  if not IsTextureSet(texHandle) then exit;

  texture := GetTexturePtr(texHandle);

  for py:=0 to texture^.height - 1 do
  for px:=0 to texture^.width - 1 do begin
    if (x + px > ClipX2) or (x + px < ClipX1)
      or (y + py > ClipY2) or (y + py < ClipY1) then continue;

    { offset to the pixel data }
    offset := (px + py * texture^.width) * 4;

    alpha := texture^.pixelData[offset + 3];
    if alpha < 255 then continue;

    colour := UnsafeSprPget(texture, px, py);
    UnsafePset(x + px, y + py, colour)
  end;
end;

procedure SprClear(const texHandle: longint; const colour: longword);
var
  texture: PSoftwareTex;
  px, py: smallint;
begin
  if not IsTextureSet(texHandle) then exit;

  texture := GetTexturePtr(texHandle);

  for py:=0 to texture^.height - 1 do
  for px:=0 to texture^.width - 1 do
    UnsafeSprPset(texture, px, py, colour);
end;

procedure SprRegion(
  const texHandle: longint;
  const srcX, srcY, srcW, srcH: smallint;
  const destX, destY: smallint);
var
  texture: PSoftwareTex;
  a, b: smallint;
  sx, sy: smallint;
  srcPos: longword;
  alpha: byte;
  colour: longword;
begin
  if not IsTextureSet(texHandle) then exit;

  texture := GetTexturePtr(texHandle);

  for b:=0 to srcH - 1 do
  for a:=0 to srcW - 1 do begin
    if (destX + a > ClipX2) or (destX + a < ClipX1)
      or (destY + b > ClipY2) or (destY + b < ClipY1) then continue;

    sx := srcX + a;
    sy := srcY + b;
    srcPos := (sx + sy * texture^.width) * 4;

    alpha := texture^.pixelData[srcPos + 3];
    if alpha < 255 then continue;

    colour := UnsafeSprPget(texture, sx, sy);
    UnsafePset(destX + a, destY + b, colour);
  end;
end;

{ Stretch a sprite with nearest neighbour scaling }
procedure SprStretch(const texHandle: longint; const destX, destY, destWidth, destHeight: smallint);
var
  sx, sy: smallint;
  dx, dy: smallint;
  srcPos: longword;
  texture: PSoftwareTex;
  alpha: byte;
  scaleX, scaleY: double;
  colour: longword;
begin
  if not IsTextureSet(texHandle) then exit;
  texture := GetTexturePtr(texHandle);

  scaleX := texture^.width / destWidth;
  scaleY := texture^.height / destHeight;

  for dy := 0 to destHeight - 1 do
  for dx := 0 to destWidth - 1 do begin
    if (destX + dx > ClipX2) or (destX + dx < ClipX1)
      or (destY + dy > ClipY2) or (destY + dy < ClipY1) then continue;

    sx := trunc(dx * scaleX);
    sy := trunc(dy * scaleY);

    srcPos := (sx + sy * texture^.width) * 4;
    alpha := texture^.pixelData[srcPos + 3];
    if alpha < 255 then continue;

    colour := UnsafeSprPget(texture, sx, sy);
    UnsafePset(dx + destX, dy + destY, colour);
  end;
end;

procedure SprRegionStretch(
  const texHandle: longint;
  const srcX, srcY, srcWidth, srcHeight: smallint;
  const destX, destY, destWidth, destHeight: smallint);
var
  sx, sy: smallint;
  dx, dy: smallint;
  texture: PSoftwareTex;
  alpha: byte;
  scaleX, scaleY: double;
  colour: longword;
begin
  if not IsTextureSet(texHandle) then exit;
  texture := GetTexturePtr(texHandle);

  scaleX := srcWidth / destWidth;
  scaleY := srcHeight / destHeight;

  for dy := 0 to destHeight - 1 do
  for dx := 0 to destWidth - 1 do begin
    if (destX + dx > ClipX2) or (destX + dx < ClipX1)
      or (destY + dy > ClipY2) or (destY + dy < ClipY1) then continue;

    { Map destination pixel to source region }
    sx := srcX + trunc(dx * scaleX);
    sy := srcY + trunc(dy * scaleY);

    if (sx >= texture^.width) or (sx < 0)
      or (sy >= texture^.height) or (sy < 0) then continue;

    colour := UnsafeSprPget(texture, sx, sy);
    alpha := colour shr 24;
    if alpha < 255 then continue;

    UnsafePset(dx + destX, dy + destY, colour)
  end;
end;

procedure SprRegionSolid(
  const texHandle: longint;
  const srcX, srcY, srcW, srcH: smallint;
  const destX, destY: smallint;
  const colour: longword);
var
  texture: PSoftwareTex;
  a, b: smallint;
  sx, sy: smallint;
  srcPos: longword;
  alpha: byte;
begin
  if not IsTextureSet(texHandle) then exit;

  texture := GetTexturePtr(texHandle);

  for b:=0 to srcH - 1 do
  for a:=0 to srcW - 1 do begin
    if (destX + a > ClipX2) or (destX + a < ClipX1)
      or (destY + b > ClipY2) or (destY + b < ClipY1) then continue;

    sx := srcX + a;
    sy := srcY + b;
    srcPos := (sx + sy * texture^.width) * 4;

    alpha := texture^.pixelData[srcPos + 3];
    if alpha < 255 then continue;

    { colour := UnsafeSprPget(texture, sx, sy); }
    UnsafePset(destX + a, destY + b, colour);
  end;
end;

{ flip: use SprFlips enum }
procedure SprFlip(const texHandle: longint; const x, y: smallint; const flip: smallint);
var
  sx, sy: smallint;
  dx, dy: smallint;
  srcPos: longword;
  texture: PSoftwareTex;
  alpha: byte;
  colour: longword;
begin
  if flip = SprFlipNone then begin
    Spr(texHandle, x, y);
    exit
  end;

  if not IsTextureSet(texHandle) then exit;

  texture := GetTexturePtr(texHandle);

  for sy := 0 to texture^.height - 1 do
  for sx := 0 to texture^.width - 1 do begin
    srcPos := (sx + sy * texture^.width) * 4;
    alpha := texture^.pixelData[srcPos + 3];
    if alpha < 255 then continue;

    dx := x + sx;
    dy := y + sy;

    case flip of
      SprFlipHorizontal:
        dx := x + texture^.width - sx - 1;
      SprFlipVertical:
        dy := y + texture^.height - sy - 1;
      else begin
        dx := x + texture^.width - sx - 1;
        dy := y + texture^.height - sy - 1;
      end
    end;

    if (dx > ClipX2) or (dx < ClipX1)
      or (dy > ClipY2) or (dy < ClipY1) then continue;

    colour := UnsafeSprPget(texture, sx, sy);
    UnsafePset(dx, dy, colour);
  end;
end;

procedure SprRotate(const texHandle: longint; const cx, cy: smallint; const rotation: double);
var
  sx, sy: double;
  dx, dy: smallint;
  srcPos: longword;
  srcX, srcY: smallint;
  texture: PSoftwareTex;

  alpha: byte;
  colour: longword;

  cosAngle, sinAngle: double;
  halfW, halfH: smallint;
  maxRadius: smallint;
begin
  if not IsTextureSet(texHandle) then exit;
  texture := GetTexturePtr(texHandle);

  { Negative for inverse transform }
  cosAngle := cos(-rotation);
  sinAngle := sin(-rotation);

  halfW := texture^.width div 2;
  halfH := texture^.height div 2;

  maxRadius := trunc(sqrt(halfW * halfW + halfH * halfH)) + 1;
  
  for dy := -maxRadius to maxRadius do
  for dx := -maxRadius to maxRadius do begin
    if (cx + dx < ClipX1) or (cx + dx > ClipX2)
      or (cy + dy < ClipY1) or (cy + dy > ClipY2) then continue;

    sx := dx * cosAngle - dy * sinAngle;
    sy := dx * sinAngle + dy * cosAngle;

    srcX := trunc(sx) + halfW;
    srcY := trunc(sy) + halfH;

    if (srcX < 0) or (srcX >= texture^.width)
      or (srcY < 0) or (srcY >= texture^.height) then continue;

    srcPos := (srcX + srcY * texture^.width) * 4;
    alpha := texture^.pixelData[srcPos + 3];
    if alpha < 255 then continue;

    colour := UnsafeSprPget(texture, srcX, srcY);
    UnsafePset(cx + dx, cy + dy, colour)
  end;
end;


procedure SprToDest(const src, dest: longint; const x, y: smallint);
var
  srcTex, destTex: PSoftwareTex;
  startX, endX, startY, endY: word;
  a, b: smallint;
  srcOffset: longword;
  alpha: byte;
  colour: longword;
begin
  if not IsTextureSet(src) or not IsTextureSet(dest) then exit;

  srcTex := GetTexturePtr(src);
  destTex := GetTexturePtr(dest);

  startX := trunc(max(0, -x));
  startY := trunc(max(0, -y));
  endX := trunc(min(srcTex^.width, destTex^.width - x));
  endY := trunc(min(srcTex^.height, destTex^.height - y));

  for b:=startY to endY - 1 do
  for a:=startX to endX - 1 do begin
    srcOffset := (a + b * srcTex^.width) * 4;
    alpha := srcTex^.pixelData[srcOffset + 3];
    if alpha < 255 then continue;

    colour := UnsafeSprPget(srcTex, a, b);
    UnsafeSprPset(destTex, x + a, y + b, colour)
  end;
end;

procedure SprRegionToDest(
  const src, dest: longint;
  const srcX, srcY, srcW, srcH: smallint;
  const destX, destY: smallint);
var
  srcTex, destTex: PSoftwareTex;
  px, py: smallint;
  sx, sy: smallint;
  srcPos: longword;
  alpha: byte;
  colour: longword;
begin
  if not IsTextureSet(src) or not IsTextureSet(dest) then exit;

  srcTex := GetTexturePtr(src);
  destTex := GetTexturePtr(dest);

  for py:=0 to srcH - 1 do
  for px:=0 to srcW - 1 do begin
    if (destX + px >= destTex^.width) or (destX + px < 0)
      or (destY + py >= destTex^.height) or (destY + py < 0) then continue;

    sx := srcX + px;
    sy := srcY + py;
    srcPos := (sx + sy * srcTex^.width) * 4;

    alpha := srcTex^.pixelData[srcPos + 3];
    if alpha < 255 then continue;

    colour := UnsafeSprPget(srcTex, sx, sy);
    UnsafeSprPset(destTex, destX + px, destY + py, colour);
  end;
end;

{ flip: Use SprFlip enum }
procedure SprFlipInPlace(const texHandle: longint; const flip: smallint);
var
  texture: PSoftwareTex;
  px, py: smallint;
  halfW, halfH: smallint;
  tempColour: longword;
  pos1, pos2: longint;
begin
  if flip = SprFlipNone then exit;
  if not IsTextureSet(texHandle) then exit;

  texture := GetTexturePtr(texHandle);

  { Horizontal flip }
  if (flip and SprFlipHorizontal) <> 0 then begin
    halfW := texture^.width div 2;

    for py:=0 to texture^.height - 1 do
    for px:=0 to halfW - 1 do begin
      pos1 := (px + py * texture^.width) * 4;
      pos2 := ((texture^.width - 1 - px) + py * texture^.width) * 4;

      { Swap RGBA }
      tempColour := PLongword(@texture^.pixelData[pos1])^;
      PLongword(@texture^.pixelData[pos1])^ := PLongword(@texture^.pixelData[pos2])^;
      PLongword(@texture^.pixelData[pos2])^ := tempColour
    end;
  end;

  { Vertical flip }
  if (flip and SprFlipVertical) <> 0 then begin
    halfH := texture^.height div 2;

    for py:=0 to halfH - 1 do
    for px:=0 to texture^.width - 1 do begin
      pos1 := (px + py * texture^.width) * 4;
      pos2 := (px + (texture^.height - 1 - py) * texture^.width) * 4;

      { Swap RGBA }
      tempColour := PLongword(@texture^.pixelData[pos1])^;
      PLongword(@texture^.pixelData[pos1])^ := PLongword(@texture^.pixelData[pos2])^;
      Plongword(@texture^.pixelData[pos2])^ := tempColour
    end;
  end;
end;


end.
