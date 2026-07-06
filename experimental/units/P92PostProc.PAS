{
  Software Post-processing unit
  Part of Posit-92 game engine
  By Hevanafa
}

unit P92PostProc;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses P92Tex;

type FalloffTypes = (
  FalloffTypeSmoothstep,  { default }
  FalloffTypeLinear,
  FalloffTypeEaseInQuad,
  FalloffTypeEaseOutQuad,
  FalloffTypeCount
);

procedure ApplyGreyscale(const texHandle: longint);
procedure ApplyFullScanlines;
procedure ApplyFullSubtleScanlines;
procedure ApplyFullTint(const tint: longword);
procedure ApplyFullBoxBlur(const radius: smallint);
procedure ApplyFullChromabe;

function GetFalloffName(const which: FalloffTypes): string;
procedure ApplyFullVignette(const falloffType: FalloffTypes; const strength: double);

procedure ApplyFullPhosphor(const radius: smallint);

implementation

uses
  P92Conversions, P92TexDraw, P92Easings, P92Logger, P92VGA;

var
  texBlur: longint;
  texBlurPtr: PSoftwareTex;
  texChromabe: longint;
  texChromabePtr: PSoftwareTex;

  texVignette: longint;
  texVignettePtr: PSoftwareTex;
  texPhosphor: longint;
  texPhosphorPtr: PSoftwareTex;

procedure ApplyGreyscale(const texHandle: longint);
var
  texture: PSoftwareTex;
  px, py: smallint;
  r, g, b, a: byte;
  grey: byte;
  colour: longword;
begin
  if not IsTextureSet(texHandle) then exit;

  texture := GetTexturePtr(texHandle);

  for py:=0 to texture^.height - 1 do
  for px:=0 to texture^.width - 1 do begin
    colour := unsafeSprPget(texture, px, py);

    a := colour shr 24 and $FF;
    r := colour shr 16 and $FF;
    g := colour shr 8 and $FF;
    b := colour and $FF;

    grey := trunc(r * 0.299 + g * 0.587 + b * 0.114);
    colour := ((a shl 8 or grey) shl 8 or grey) shl 8 or grey;
    unsafeSprPset(texture, px, py, colour)
  end;
end;


procedure ApplyFullScanlines;
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

procedure ApplyFullSubtleScanlines;
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

procedure ApplyFullTint(const tint: longword);
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


procedure ApplyFullBoxBlur(const radius: smallint);
var
  a, b, c, d: smallint;
  colour: longword;
  count: word;
  red, green, blue: word;
begin
  if radius <= 0 then exit;

  if texBlurPtr = nil then begin
    texBlur := NewTexture(vgaWidth, vgaHeight);
    texBlurPtr := GetTexturePtr(texBlur);
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

      { Output to texBlur }
      colour := ($FF shl 24) or (red shl 16) or (green shl 8) or blue;
      unsafeSprPset(texBlurPtr, a, b, colour)
    end;

  spr(texBlur, 0, 0)
end;


procedure ApplyFullChromabe;
var
  px, py: smallint;
  redPixel, greenPixel, bluePixel: longword;
  r, g, b, a: byte;
  redX, blueX: smallint;
  colour: longword;
begin
  if texChromabePtr = nil then begin
    texChromabe := NewTexture(vgaWidth, vgaHeight);
    texChromabePtr := GetTexturePtr(texChromabe);
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
      unsafeSprPset(texChromabePtr, px, py, colour)
    end;

  spr(texChromabe, 0, 0)
end;

function GetFalloffName(const which: FalloffTypes): string;
begin
  case which of
    FalloffTypeSmoothstep:
      GetFalloffName := 'Smoothstep';
    FalloffTypeLinear:
      GetFalloffName := 'Linear';

    FalloffTypeEaseInQuad:
      GetFalloffName := 'Ease in quad';
    FalloffTypeEaseOutQuad:
      GetFalloffName := 'Ease out quad';

    else result := 'Unknown falloff type: ' + i32str(ord(which));
  end;
end;

{ strength: Either 0.3 or 0.7 }
procedure ApplyFullVignette(const falloffType: FalloffTypes; const strength: double);
var
  px, py: smallint;
  centreX, centreY: double;
  offsetX, offsetY: double;
  normX, normY: double;
  dist, t, factor: double;
  a, r, g, b: byte;
  colour: longword;
begin
  if texVignettePtr = nil then begin
    texVignette := NewTexture(vgaWidth, vgaHeight);
    texVignettePtr := GetTexturePtr(texVignette);
  end;

  if strength < 0.05 then exit;

  { WriteLog('DEBUG applyFullVignette'); }

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
{
    WriteLog('normX, normY, dist');
    writeLogF32(normX);
    writeLogF32(normY);
    writeLogF32(dist);
}

    { Vignette factor (falloff) }
    { t: gradient }
    t := 1.0 - dist;
    if t < 0.0 then t := 0.0;
    if t > 1.0 then t := 1.0;

{
    WriteLog('t after clamp');
    writeLogF32(t);
}

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
{
    WriteLog('factor after falloffType');
    writeLogF32(factor);
}

    { Apply strength }
    factor := 1.0 - (1.0 - factor) * strength;

{
    WriteLog('factor after apply strength');
    writeLogF32(factor);
}

    { Darken RGB channels with vignette factor }
    colour := unsafePget(px, py);

    r := colour shr 16 and $FF;
    g := colour shr 8 and $FF;
    b := colour and $FF;
    a := colour shr 24 and $FF;
{
    WriteLog('rgb with factor');
    writeLogF32(r * factor);
    writeLogF32(g * factor);
    writeLogF32(b * factor);
}

    r := trunc(r * factor);
    g := trunc(g * factor);
    b := trunc(b * factor);

    { Render to buffer }
    colour := (a shl 24) or (r shl 16) or (g shl 8) or b;
    unsafeSprPset(texVignettePtr, px, py, colour)
  end;

  spr(texVignette, 0, 0)
end;

{ Based on box blur }
procedure ApplyFullPhosphor(const radius: smallint);
const
  { blendAmount: double = 0.7; } { 70% original, 30% blur }
  blendAmount: double = 0.3;  { 30% original, 70% blur }
  brightnessMult: double = 1.2;
var
  a, b, c, d: smallint;
  colour: longword;
  count: word;
  red, green, blue: word;

  origColour, blurColour: longword;
  origR, origG, origB: byte;
  blurR, blurG, blurB: byte;
  finalR, finalG, finalB: word;
begin
  if radius <= 0 then exit;

  if texPhosphorPtr = nil then begin
    texPhosphor := NewTexture(vgaWidth, vgaHeight);
    texPhosphorPtr := GetTexturePtr(texPhosphor);
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

      { Output to texBlur }
      colour := ($FF shl 24) or (red shl 16) or (green shl 8) or blue;
      unsafeSprPset(texPhosphorPtr, a, b, colour)
    end;

  { spr(texPhosphor, 0, 0) }

  { Blend back to VGA }
  for b:=0 to vgaHeight - 1 do
    for a:=0 to vgaWidth - 1 do begin
      { Get original from VGA }
      origColour := unsafePget(a, b);
      origR := origColour shr 16 and $FF;
      origG := origColour shr 8 and $FF;
      origB := origColour and $FF;

      { Get blurred pixel }
      blurColour := unsafeSprPget(texPhosphorPtr, a, b);
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

  { spr(texPhosphor, 0, 0) }
end;

end.
