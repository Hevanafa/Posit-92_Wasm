unit PostProc;

{$Mode TP}

interface

uses ImgRef;

procedure applyGreyscale(const imgHandle: longint);
procedure applyFullScanlines;
procedure applyFullSubtleScanlines;


implementation

uses VGA;

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

end.
