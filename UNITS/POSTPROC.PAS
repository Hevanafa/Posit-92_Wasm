unit PostProc;

interface

uses ImgRef;

procedure applyGreyscale(const imgHandle: longint);


implementation

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

end.
