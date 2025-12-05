unit PostProc;

{$Mode TP}

interface

uses ImgRef;

procedure applyGreyscale(const imgHandle: longint);
procedure replaceColours(const imgHandle: longint; const oldColour, newColour: longword);
procedure applyFullScanlines;
procedure applyFullSubtleScanlines;
procedure applyFullTint(const tint: longword);
procedure applyFullBoxBlur(const radius: integer);


implementation

uses ImgRefFast, VGA;

var
  imgBlur: longint;
  imgBlurPtr: PImageRef;

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


end.
