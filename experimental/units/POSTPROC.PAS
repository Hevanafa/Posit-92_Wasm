unit PostProc;

{$Mode TP}

interface

uses ImgRef;

type FalloffTypes = (
  FalloffTypeSmoothstep,  { default }
  FalloffTypeLinear,
  FalloffTypeEaseInQuad,
  FalloffTypeEaseOutQuad,
  FalloffTypeCount
);

procedure applyGreyscale(const imgHandle: longint);
procedure replaceColours(const imgHandle: longint; const oldColour, newColour: longword);
procedure applyFullScanlines;
procedure applyFullSubtleScanlines;
procedure applyFullTint(const tint: longword);
procedure applyFullBoxBlur(const radius: integer);
procedure applyFullChromabe;

function getFalloffName(const which: FalloffTypes): string;
procedure applyFullVignette(const falloffType: FalloffTypes; const strength: double);

procedure applyFullPhosphor(const radius: integer);

implementation

uses
  Conv, ImgRefFast, Lerp, Logger, VGA;

var
  imgBlur: longint;
  imgBlurPtr: PImageRef;
  imgChromabe: longint;
  imgChromabePtr: PImageRef;

  imgVignette: longint;
  imgVignettePtr: PImageRef;
  imgPhosphor: longint;
  imgPhosphorPtr: PImageRef;

procedure applyGreyscale(const imgHandle: longint);
var
  image: PImageRef;
  px, py: integer;
  r, g, b, a: byte;
  grey: byte;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  image := getImagePtr(imgHandle);

  for py:=0 to image^.height - 1 do
  for px:=0 to image^.width - 1 do begin
    colour := unsafeSprPget(image, px, py);

    a := colour shr 24 and $FF;
    r := colour shr 16 and $FF;
    g := colour shr 8 and $FF;
    b := colour and $FF;

    grey := trunc(r * 0.299 + g * 0.587 + b * 0.114);
    colour := ((a shl 8 or grey) shl 8 or grey) shl 8 or grey;
    unsafeSprPset(image, px, py, colour)
  end;
end;

procedure replaceColours(const imgHandle: longint; const oldColour, newColour: longword);
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


procedure applyFullScanlines;
var
  px, py: word;
  r, g, b: byte;
  colour: longword;
begin
  py:=1;
  while py < vgaHeight do begin
    for px:=0 to vgaWidth - 1 do begin
      colour := unsafePget(px, py);

      { Darken by 50% }
      r := colour shr 16 and $FF;
      g := colour shr 8 and $FF;
      b := colour and $FF;

      r := r shr 1;
      g := g shr 1;
      b := b shr 1;

      colour := (colour and $FF000000) or (r shl 16) or (g shl 8) or b;

      unsafePset(px, py, colour);
    end;

    inc(py, 2);
  end;
end;

procedure applyFullSubtleScanlines;
var
  px, py: word;
  r, g, b: byte;
  colour: longword;
begin
  py:=1;
  while py < vgaHeight do begin
    for px:=0 to vgaWidth - 1 do begin
      colour := unsafePget(px, py);

      { Darken by 25% }
      r := colour shr 16 and $FF;
      g := colour shr 8 and $FF;
      b := colour and $FF;

      r := r - r shr 2;
      g := g - g shr 2;
      b := b - b shr 2;

      colour := (colour and $FF000000) or (r shl 16) or (g shl 8) or b;

      unsafePset(px, py, colour);
    end;

    inc(py, 2);
  end;
end;

procedure applyFullTint(const tint: longword);
var
  px, py: word;
  colour: longword;
  r, g, b: byte;
  tintR, tintG, tintB: byte;
begin
  tintR := tint shr 16 and $FF;
  tintG := tint shr 8 and $FF;
  tintB := tint and $FF;

  for py:=0 to vgaHeight - 1 do
  for px:=0 to vgaWidth - 1 do begin
    colour := unsafePget(px, py);
    
    r := colour shr 16 and $FF;
    g := colour shr 8 and $FF;
    b := colour and $FF;

    r := (r * tintR) div 255;
    g := (g * tintG) div 255;
    b := (b * tintB) div 255;

    colour := (colour and $FF000000) or (r shl 16) or (g shl 8) or b;
    unsafePset(px, py, colour)
  end;
end;


procedure applyFullBoxBlur(const radius: integer);
var
  a, b, c, d: integer;
  colour: longword;
  count: word;
  red, green, blue: word;
begin
  if radius <= 0 then exit;

  if imgBlurPtr = nil then begin
    imgBlur := newImage(vgaWidth, vgaHeight);
    imgBlurPtr := getImagePtr(imgBlur);
  end;

  { Process from VGA (alpha channel is ignored) }
  for b:=0 to vgaHeight - 1 do
    for a:=0 to vgaWidth - 1 do begin
      red := 0;
      green := 0;
      blue := 0;
      count := 0;

      for d := -radius to radius do
        for c := -radius to radius do begin
          if (a + c < 0) or (a + c >= vgaWidth)
            or (b + d < 0) or (b + d >= vgaHeight) then continue;

          colour := unsafePget(a + c, b + d);

          inc(red, colour shr 16 and $FF);
          inc(green, colour shr 8 and $FF);
          inc(blue, colour and $FF);

          inc(count)
        end;

      { Average this pixel }
      red := red div count;
      green := green div count;
      blue := blue div count;

      { Output to imgBlur }
      colour := ($FF shl 24) or (red shl 16) or (green shl 8) or blue;
      unsafeSprPset(imgBlurPtr, a, b, colour)
    end;

  spr(imgBlur, 0, 0)
end;


procedure applyFullChromabe;
var
  px, py: integer;
  redPixel, greenPixel, bluePixel: longword;
  r, g, b, a: byte;
  redX, blueX: integer;
  colour: longword;
begin
  if imgChromabePtr = nil then begin
    imgChromabe := newImage(vgaWidth, vgaHeight);
    imgChromabePtr := getImagePtr(imgChromabe);
  end;

  for py:=0 to vgaHeight - 1 do
    for px:=0 to vgaWidth - 1 do begin
      { red shifts right }
      redX := px + 1;
      if redX >= vgaWidth then redX := vgaWidth - 1;

      { blue shifts left }
      blueX := px - 1;
      if blueX < 0 then blueX := 0;

      redPixel := unsafePget(redX, py);
      greenPixel := unsafePget(px, py);
      bluePixel := unsafePget(blueX, py);

      { Extract each channels }
      r := redPixel shr 16 and $FF;
      g := greenPixel shr 8 and $FF;
      b := bluePixel and $FF;
      a := greenPixel shr 24 and $FF;  { Use green's alpha }

      colour := (a shl 24) or (r shl 16) or (g shl 8) or b;
      unsafeSprPset(imgChromabePtr, px, py, colour)
    end;

  spr(imgChromabe, 0, 0)
end;

function getFalloffName(const which: FalloffTypes): string;
var
  result: string;
begin
  case which of
    FalloffTypeSmoothstep: result := 'Smoothstep';
    FalloffTypeLinear: result := 'Linear';
    FalloffTypeEaseInQuad: result := 'Ease in quad';
    FalloffTypeEaseOutQuad: result := 'Ease out quad';
    else result := 'Unknown falloff type: ' + i32str(ord(which));
  end;

  getFalloffName := result
end;

procedure applyFullVignette(const falloffType: FalloffTypes; const strength: double);
{ const
  strength: double = 0.7; } { Either 0.3 or 0.7 }
var
  px, py: integer;
  centreX, centreY: double;
  offsetX, offsetY: double;
  normX, normY: double;
  dist, t, factor: double;
  a, r, g, b: byte;
  colour: longword;
begin
  if imgVignettePtr = nil then begin
    imgVignette := newImage(vgaWidth, vgaHeight);
    imgVignettePtr := getImagePtr(imgVignette);
  end;

  writeLog('DEBUG applyFullVignette');

  for py:=0 to vgaHeight - 1 do 
  for px:=0 to vgaWidth - 1 do begin
    { Coordinate normalisation }
    centreX := vgaWidth / 2;
    centreY := vgaHeight / 2;

    offsetX := px - centreX;
    offsetY := py - centreY;

    normX := offsetX / centreX;
    normY := offsetY / centreY;

    { Elliptical distance }
    dist := sqrt(normX * normX + normY * normY);

    writeLog('normX, normY, dist');
    writeLogF32(normX);
    writeLogF32(normY);
    writeLogF32(dist);

    { Vignette factor (falloff) }
    { t: gradient }
    t := 1.0 - dist;
    if t < 0.0 then t := 0.0;
    if t > 1.0 then t := 1.0;

    writeLog('t after clamp');
    writeLogF32(t);

    case falloffType of
      FalloffTypeLinear:
        factor := lerpLinear(0.0, 1.0, t);

      FalloffTypeEaseInQuad:
        factor := lerpEaseInQuad(0.0, 1.0, t);
      FalloffTypeEaseOutQuad:
        factor := lerpEaseOutQuad(0.0, 1.0, t);

      else { Default: FalloffTypeSmoothstep }
        factor := t * t * (3.0 - 2.0 * t);
    end;

    writeLog('factor after falloffType');
    writeLogF32(factor);

    { Apply strength }
    factor := 1.0 - (1.0 - factor) * strength;

    writeLog('factor after apply strength');
    writeLogF32(factor);

    { Darken RGB channels with vignette factor }
    colour := unsafePget(px, py);

    r := colour shr 16 and $FF;
    g := colour shr 8 and $FF;
    b := colour and $FF;
    a := colour shr 24 and $FF;

    writeLog('rgb with factor');
    writeLogF32(r * factor);
    writeLogF32(g * factor);
    writeLogF32(b * factor);

    r := trunc(r * factor);
    g := trunc(g * factor);
    b := trunc(b * factor);

    { Render to buffer }
    colour := (a shl 24) or (r shl 16) or (g shl 8) or b;
    unsafeSprPset(imgVignettePtr, px, py, colour)
  end;

  spr(imgVignette, 0, 0)
end;

{ Based on box blur }
procedure applyFullPhosphor(const radius: integer);
const
  { blendAmount: double = 0.7; } { 70% original, 30% blur }
  blendAmount: double = 0.3;  { 30% original, 70% blur }
  brightnessMult: double = 1.2;
var
  a, b, c, d: integer;
  colour: longword;
  count: word;
  red, green, blue: word;

  origColour, blurColour: longword;
  origR, origG, origB: byte;
  blurR, blurG, blurB: byte;
  finalR, finalG, finalB: word;
begin
  if radius <= 0 then exit;

  if imgPhosphorPtr = nil then begin
    imgPhosphor := newImage(vgaWidth, vgaHeight);
    imgPhosphorPtr := getImagePtr(imgPhosphor);
  end;

  { Process from VGA (alpha channel is ignored) }
  for b:=0 to vgaHeight - 1 do
    for a:=0 to vgaWidth - 1 do begin
      red := 0;
      green := 0;
      blue := 0;
      count := 0;

      for d := -radius to radius do
        for c := -radius to radius do begin
          if (a + c < 0) or (a + c >= vgaWidth)
            or (b + d < 0) or (b + d >= vgaHeight) then continue;

          colour := unsafePget(a + c, b + d);

          inc(red, colour shr 16 and $FF);
          inc(green, colour shr 8 and $FF);
          inc(blue, colour and $FF);

          inc(count)
        end;

      { Average this pixel }
      red := red div count;
      green := green div count;
      blue := blue div count;

      { Output to imgBlur }
      colour := ($FF shl 24) or (red shl 16) or (green shl 8) or blue;
      unsafeSprPset(imgPhosphorPtr, a, b, colour)
    end;

  { spr(imgPhosphor, 0, 0) }

  { Blend back to VGA }
  for b:=0 to vgaHeight - 1 do
    for a:=0 to vgaWidth - 1 do begin
      { Get original from VGA }
      origColour := unsafePget(a, b);
      origR := origColour shr 16 and $FF;
      origG := origColour shr 8 and $FF;
      origB := origColour and $FF;

      { Get blurred pixel }
      blurColour := unsafeSprPget(imgPhosphorPtr, a, b);
      blurR := blurColour shr 16 and $FF;
      blurG := blurColour shr 8 and $FF;
      blurB := blurColour and $FF;

      { Handle blending }
      finalR := trunc(origR * blendAmount + blurR * (1.0 - blendAmount));
      finalG := trunc(origG * blendAmount + blurG * (1.0 - blendAmount));
      finalB := trunc(origB * blendAmount + blurB * (1.0 - blendAmount));

      { Brighten logic }
      finalR := trunc(finalR * brightnessMult);
      finalG := trunc(finalG * brightnessMult);
      finalB := trunc(finalB * brightnessMult);

      { Clamp to 255 }
      if finalR > $FF then finalR := $FF;
      if finalG > $FF then finalG := $FF;
      if finalB > $FF then finalB := $FF;

      { Write back to VGA }
      colour := ($FF shl 24) or (finalR shl 16) or (finalG shl 8) or finalB;
      unsafePset(a, b, colour)
    end;

  { spr(imgPhosphor, 0, 0) }
end;

end.
