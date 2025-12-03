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

    { TODO: Apply grey filter }
    { TODO: unsafeSprPset }
  end;
  
end;

end.
