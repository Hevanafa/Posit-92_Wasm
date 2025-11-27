{
  SprFast unit
  Part of Posit-92 framework
  By Hevanafa, 26-11-2025

  An extension of Bitmap unit
}

unit SprFast;

interface

{ Direct VGA blitting }
procedure spr(const imgHandle: longint; const x, y: integer);
procedure sprRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);

procedure sprRegionSolid(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const colour: longword);

procedure sprFlip(const imgHandle: longint; const x, y: integer; const flip: integer);
procedure sprStretch(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);
procedure sprScale(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);

procedure sprRegionStretch(
  const imgHandle: longint;
  const srcX, srcY, srcWidth, srcHeight: integer;
  const destX, destY, destWidth, destHeight: integer);
procedure sprRegionScale(
  const imgHandle: longint;
  const srcX, srcY, srcWidth, srcHeight: integer;
  const destX, destY, destWidth, destHeight: integer);

{ rotation is in radians }
procedure sprRotate(const imgHandle: longint; const cx, cy: integer; const rotation: double);

{ Blitting on another sprite }
procedure sprOnSprite(const srcHandle, destHandle: longint; const x, y: integer);

{ spr with TImageRef }
procedure sprRef(const handle: longint; const x, y: integer);


implementation

uses Bitmap, Logger, VGA;

var
  sprRefOnceA, sprRefOnceB: boolean;

procedure spr(const imgHandle: longint; const x, y: integer);
var
  image: PBitmap;
  a, b: integer;
  srcPos: longint;
  alpha: byte;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for b:=0 to image^.height - 1 do
  for a:=0 to image^.width - 1 do begin
    if (x + a >= vgaWidth) or (x + a < 0)
      or (y + b >= vgaHeight) or (y + b < 0) then continue;

    srcPos := (a + b * image^.width) * 4;
    alpha := image^.data[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, a, b);
    unsafePset(x + a, y + b, colour);
  end;
end;

procedure sprRegion(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer);
var
  image: PBitmap;
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

    alpha := image^.data[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, sx, sy);
    unsafePset(destX + a, destY + b, colour);
  end;
end;

procedure sprRegionSolid(
  const imgHandle: longint;
  const srcX, srcY, srcW, srcH: integer;
  const destX, destY: integer;
  const colour: longword);
var
  image: PBitmap;
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

    alpha := image^.data[srcPos + 3];
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
  image: PBitmap;
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
    alpha := image^.data[srcPos + 3];
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

{ Stretch a sprite with nearest neighbour scaling }
procedure sprStretch(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);
var
  sx, sy: integer;
  dx, dy: integer;
  srcPos: longint;
  image: PBitmap;
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
    alpha := image^.data[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, sx, sy);
    unsafePset(dx + destX, dy + destY, colour);
  end;
end;

procedure sprScale(const imgHandle: longint; const destX, destY, destWidth, destHeight: integer);
begin
  sprStretch(imgHandle, destX, destY, destWidth, destHeight)
end;

procedure sprRegionStretch(
  const imgHandle: longint;
  const srcX, srcY, srcWidth, srcHeight: integer;
  const destX, destY, destWidth, destHeight: integer);
var
  sx, sy: integer;
  dx, dy: integer;
  image: PBitmap;
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

procedure sprRegionScale(
  const imgHandle: longint;
  const srcX, srcY, srcWidth, srcHeight: integer;
  const destX, destY, destWidth, destHeight: integer);
begin
  sprRegionStretch(imgHandle,
    srcX, srcY, srcWidth, srcHeight,
    destX, destY, destWidth, destHeight)
end;


procedure sprRotate(const imgHandle: longint; const cx, cy: integer; const rotation: double);
var
  sx, sy: double;
  dx, dy: integer;
  srcPos: longint;
  srcX, srcY: integer;
  image: PBitmap;

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
    alpha := image^.data[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(image, srcX, srcY);
    unsafePset(cx + dx, cy + dy, colour)
  end;
end;


procedure sprOnSprite(const srcHandle, destHandle: longint; const x, y: integer);
var
  srcImage, destImage: PBitmap;
  a, b: integer;
  srcPos: longint;
  alpha: byte;
  colour: longword;
begin
  if not isImageSet(srcHandle) then exit;
  if not isImageSet(destHandle) then exit;

  srcImage := getImagePtr(srcHandle);
  destImage := getImagePtr(destHandle);

  for b:=0 to srcImage^.height - 1 do
  for a:=0 to srcImage^.width - 1 do begin
    if (x + a >= destImage^.width) or (x + a < 0)
      or (y + b >= destImage^.height) or (y + b < 0) then continue;

    srcPos := (a + b * srcImage^.width) * 4;
    alpha := srcImage^.data[srcPos + 3];
    if alpha < 255 then continue;

    colour := unsafeSprPget(srcImage, a, b);
    unsafeSprPset(destImage, x + a, y + b, colour)
  end;
end;

procedure sprRef(const handle: longint; const x, y: integer);
var
  ref: TImageRef;
  px, py: integer;
  offset: longword;
  data: PByte;
  r, g, b, a: byte;
  colour: longword;
begin
  if not sprRefOnceA then begin
    writeLog('sprRef handle');
    writeLogI32(handle);
    sprRefOnceA := true
  end;

  { if (handle < 1) or (handle >= getImageRefCount) then exit; }
  { TODO: Handle if image is set }

  ref := getImageRef(handle);

  if not sprRefOnceB then begin
    writeLog('Got image ref');
    writeLogI32(ref.width);
    writeLogI32(ref.height);
    sprRefOnceB := true
  end;

  data := PByte(ref.dataPtr);

  for py:=0 to ref.height - 1 do
  for px:=0 to ref.width - 1 do begin
    if (x + px >= vgaWidth) or (x + px < 0)
      or (y + py >= vgaHeight) or (y + py < 0) then continue;

    { offset to ImageData buffer }
    offset := (px + py * ref.width) * 4;

    r := data[offset];
    g := data[offset + 1];
    b := data[offset + 2];
    a := data[offset + 3];

    if a < 255 then continue;

    colour := (a shl 24) or (r shl 16) or (g shl 8) or b;
    unsafePset(x + px, y + py, colour)
  end;
end;

end.
