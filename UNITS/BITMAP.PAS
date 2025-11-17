unit Bitmap;

interface

type
  PBitmap = ^TBitmap;
  TBitmap = record
    width, height: word;
    data: array[0..127999] of byte;
  end;

function getImageBuffer: pointer; public name 'getImageBuffer';
procedure spr(const imagePtr: pointer; const x, y: integer); public name 'spr';


implementation

uses VGA;

{ Bitmap operations }
const
  maxImageBufferSize = 128 * 128 * 4;

var
  imageBuffer: array[0..maxImageBufferSize - 1] of byte;

function getImageBuffer: pointer;
begin
  getImageBuffer := @imageBuffer
end;

{
function allocImageData(const size: integer): pointer;
var
  ptr: pointer;
begin
  Important: This always crashes on WebAssembly
  getmem(ptr, size);
  allocImageData := ptr
end;
}

procedure spr(const imagePtr: pointer; const x, y: integer);
var
  a, b, srcPos, destPos: integer;
  surface: PByteArray;
  image: PBitmap;
begin
  if imagePtr = nil then exit;

  image := PBitmap(imagePtr);
  surface := PByteArray(getSurface);

  for b:=0 to image^.height - 1 do
  for a:=0 to image^.width - 1 do begin
    srcPos := (b * image^.width + a) * 4;
    destPos := ((y + b) * vgaWidth + (x + a)) * 4;

    { Order: RGBA }
    surface^[destPos] := image^.data[srcPos];
    surface^[destPos + 1] := image^.data[srcPos + 1];
    surface^[destPos + 2] := image^.data[srcPos + 2];
    surface^[destPos + 3] := image^.data[srcPos + 3];
  end;
end;

end.
