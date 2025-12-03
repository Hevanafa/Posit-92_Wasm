{ 
  ImgRefFast unit
  Part of Posit-92 framework
  By Hevanafa, 29-11-2025

  Based on SprFast unit
}

unit ImgRefFast;

{$Mode TP}
{$B-}  { Enable boolean short-circuiting }
{$R-}  { Turn off range checks }
{$Q-}  { Turn off overflow checks }

interface

{ spr with TImageRef }
procedure spr(const imgHandle: longint; const x, y: integer);

procedure sprClear(const imgHandle: longint; const colour: longword);

procedure sprRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);

procedure sprStretch(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);

procedure sprRegionStretch(
  const imgHandle: longint;
  const srcX, srcY, srcWidth, srcHeight: integer;
  const destX, destY, destWidth, destHeight: integer);

procedure sprRegionSolid(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const colour: longword);

procedure sprFlip(const imgHandle: longint; const x, y: integer; const flip: integer);

{ rotation is in radians }
procedure sprRotate(const imgHandle: longint; const cx, cy: integer; const rotation: double);


procedure sprToDest(const src, dest: longint; const x, y: integer);

implementation

uses ImgRef, Maths, VGA;

procedure spr(const imgHandle: longint; const x, y: integer);
var
  image: PImageRef;
  px, py: integer;
  offset: longword;
  data: PByte;
  a: byte;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);
  data := PByte(image^.dataPtr);

  for py:=0 to image^.height - 1 do
  for px:=0 to image^.width - 1 do begin
    if (x + px >= vgaWidth) or (x + px < 0)
      or (y + py >= vgaHeight) or (y + py < 0) then continue;

    { offset to ImageData buffer }
    offset := (px + py * image^.width) * 4;
    a := data[offset + 3];
    if a < 255 then continue;

    colour := unsafeSprPget(image, px, py);
    unsafePset(x + px, y + py, colour)
  end;
end;

procedure sprClear(const imgHandle: longint; const colour: longword);
var
  image: PImageRef;
  px, py: integer;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  { fillchar(image^.dataPtr, image^.width * image^.height * 4, 0); }
  for py:=0 to image^.height - 1 do
  for px:=0 to image^.width - 1 do
    unsafeSprPset(image, px, py, colour);
end;

procedure sprRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);
var
  image: PImageRef;
  a, b: integer;
  sx, sy: integer;
  srcPos: longint;
  alpha: byte;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for b:=0 to srcH - 1 do
  for a:=0 to srcW - 1 do begin
    if (destX + a >= vgaWidth) or (destX + a < 0)
      or (destY + b >= vgaHeight) or (destY + b < 0) then continue;

    sx := srcX + a;
    sy := srcY + b;
    srcPos := (sx + sy * image^.width) * 4;

    alpha := image^.dataPtr[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, sx, sy);
    unsafePset(destX + a, destY + b, colour);
  end;
end;

{ Stretch a sprite with nearest neighbour scaling }
procedure sprStretch(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);
var
  sx, sy: integer;
  dx, dy: integer;
  srcPos: longint;
  image: PImageRef;
  alpha: byte;
  scaleX, scaleY: double;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;
  image := getImagePtr(imgHandle);

  scaleX := image^.width / destWidth;
  scaleY := image^.height / destHeight;

  for dy := 0 to destHeight - 1 do
  for dx := 0 to destWidth - 1 do begin
    if (destX + dx >= vgaWidth) or (destX + dx < 0)
      or (destY + dy >= vgaHeight) or (destY + dy < 0) then continue;

    sx := trunc(dx * scaleX);
    sy := trunc(dy * scaleY);

    srcPos := (sx + sy * image^.width) * 4;
    alpha := image^.dataPtr[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, sx, sy);
    unsafePset(dx + destX, dy + destY, colour);
  end;
end;

procedure sprRegionStretch(
  const imgHandle: longint;
  const srcX, srcY, srcWidth, srcHeight: integer;
  const destX, destY, destWidth, destHeight: integer);
var
  sx, sy: integer;
  dx, dy: integer;
  image: PImageRef;
  alpha: byte;
  scaleX, scaleY: double;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;
  image := getImagePtr(imgHandle);

  scaleX := srcWidth / destWidth;
  scaleY := srcHeight / destHeight;

  for dy := 0 to destHeight - 1 do
  for dx := 0 to destWidth - 1 do begin
    if (destX + dx >= vgaWidth) or (destX + dx < 0)
      or (destY + dy >= vgaHeight) or (destY + dy < 0) then continue;

    { Map destination pixel to source region }
    sx := srcX + trunc(dx * scaleX);
    sy := srcY + trunc(dy * scaleY);

    if (sx >= image^.width) or (sx < 0)
      or (sy >= image^.height) or (sy < 0) then continue;

    colour := unsafeSprPget(image, sx, sy);
    alpha := colour shr 24;
    if alpha < 255 then continue;

    unsafePset(dx + destX, dy + destY, colour)
  end;
end;

procedure sprRegionSolid(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const colour: longword);
var
  image: PImageRef;
  a, b: integer;
  sx, sy: integer;
  srcPos: longint;
  alpha: byte;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for b:=0 to srcH - 1 do
  for a:=0 to srcW - 1 do begin
    if (destX + a >= vgaWidth) or (destX + a < 0)
      or (destY + b >= vgaHeight) or (destY + b < 0) then continue;

    sx := srcX + a;
    sy := srcY + b;
    srcPos := (sx + sy * image^.width) * 4;

    alpha := image^.dataPtr[srcPos + 3];
    if alpha < 255 then continue;

    { colour := unsafeSprPget(image, sx, sy); }
    unsafePset(destX + a, destY + b, colour);
  end;
end;

{ flip: use SprFlips enum }
procedure sprFlip(const imgHandle: longint; const x, y: integer; const flip: integer);
var
  sx, sy: integer;
  dx, dy: integer;
  srcPos: longint;
  image: PImageRef;
  alpha: byte;
  colour: longword;
begin
  if flip = SprFlipNone then begin
    spr(imgHandle, x, y);
    exit
  end;

  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for sy := 0 to image^.height - 1 do
  for sx := 0 to image^.width - 1 do begin
    srcPos := (sx + sy * image^.width) * 4;
    alpha := image^.dataPtr[srcPos + 3];
    if alpha < 255 then continue;

    dx := x + sx;
    dy := y + sy;

    case flip of
      SprFlipHorizontal:
        dx := x + image^.width - sx - 1;
      SprFlipVertical:
        dy := y + image^.height - sy - 1;
      else begin
        dx := x + image^.width - sx - 1;
        dy := y + image^.height - sy - 1;
      end
    end;

    if (dx >= vgaWidth) or (dx < 0)
      or (dy >= vgaHeight) or (dy < 0) then continue;

    colour := unsafeSprPget(image, sx, sy);
    unsafePset(dx, dy, colour);
  end;
end;

procedure sprRotate(const imgHandle: longint; const cx, cy: integer; const rotation: double);
var
  sx, sy: double;
  dx, dy: integer;
  srcPos: longint;
  srcX, srcY: integer;
  image: PImageRef;

  alpha: byte;
  colour: longword;

  cosAngle, sinAngle: double;
  halfW, halfH: integer;
  maxRadius: integer;
begin
  if not isImageSet(imgHandle) then exit;
  image := getImagePtr(imgHandle);

  { Negative for inverse transform }
  cosAngle := cos(-rotation);
  sinAngle := sin(-rotation);

  halfW := image^.width div 2;
  halfH := image^.height div 2;

  maxRadius := trunc(sqrt(halfW * halfW + halfH * halfH)) + 1;
  
  for dy := -maxRadius to maxRadius do
  for dx := -maxRadius to maxRadius do begin
    if (cx + dx < 0) or (cx + dx >= vgaWidth)
      or (cy + dy < 0) or (cy + dy >= vgaHeight) then continue;

    sx := dx * cosAngle - dy * sinAngle;
    sy := dx * sinAngle + dy * cosAngle;

    srcX := trunc(sx) + halfW;
    srcY := trunc(sy) + halfH;

    if (srcX < 0) or (srcX >= image^.width)
      or (srcY < 0) or (srcY >= image^.height) then continue;

    srcPos := (srcX + srcY * image^.width) * 4;
    alpha := image^.dataPtr[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, srcX, srcY);
    unsafePset(cx + dx, cy + dy, colour)
  end;
end;


procedure sprToDest(const src, dest: longint; const x, y: integer);
var
  srcImage, destImage: PImageRef;
  startX, endX, startY, endY: word;
  a, b: integer;
  srcOffset: longword;
  alpha: byte;
  colour: longword;
begin
  if not isImageSet(src) then exit;
  if not isImageSet(dest) then exit;

  srcImage := getImagePtr(src);
  destImage := getImagePtr(dest);

  startX := trunc(max(0, -x));
  startY := trunc(max(0, -y));
  endX := trunc(min(srcImage^.width, destImage^.width - x));
  endY := trunc(min(srcImage^.height, destImage^.height - y));

  for b:=startY to endY - 1 do
  for a:=startX to endX - 1 do begin
    srcOffset := (a + b * srcImage^.width) * 4;
    alpha := srcImage^.dataPtr[srcOffset + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(srcImage, a, b);
    unsafeSprPset(destImage, x + a, y + b, colour)
  end;
end;

end.
