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

  for py:=0 to image^.height do
  for px:=0 to image^.width do begin
    colour := unsafeSprPget(image, px, py);

    r := colour shr 24 and $FF;
    g := colour shr 16 and $FF;
    b := colour shr 8 and $FF;
    a := colour and $FF;

    grey := trunc(r * 0.299 + g * 0.587 + b * 0.114);
    colour := ((grey shl 8 or grey) shl 8 or grey) shl 8 or alpha;
    unsafeSprPset(image, px, py, colour)
  end;
end;

end.
