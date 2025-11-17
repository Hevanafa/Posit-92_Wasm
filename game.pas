library Game;

{$Mode ObjFPC}

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

{ TODO: Use a PBitmap }
procedure spr(const x, y, width, height: integer);
var
  a, b, srcPos, destPos: integer;
  surface: PByteArray;
begin
  surface := PByteArray(getSurface);

  for b:=0 to height - 1 do
  for a:=0 to width - 1 do begin
    srcPos := (b * width + a) * 4;
    destPos := ((y + b) * vgaWidth + (x + a)) * 4;

    { Order: RGBA }
    surface^[destPos] := imageBuffer[srcPos];
    surface^[destPos + 1] := imageBuffer[srcPos + 1];
    surface^[destPos + 2] := imageBuffer[srcPos + 2];
    surface^[destPos + 3] := imageBuffer[srcPos + 3];
  end;
end;


exports
  { VGA }
  initBuffer,
  getSurface,
  cls,

  { BITMAP }
  { allocImageData, }
  getImageBuffer,
  spr;

begin
{ Starting point is intentionally left empty }
end.

