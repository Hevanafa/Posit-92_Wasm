library Game;

{$Mode ObjFPC}

{ uses Classes; }

const
  bufferSize = 256000; { 64000 * 4 }
  vgaWidth = 320;
  vgaHeight = 200;

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..bufferSize - 1] of byte;

var
  surface: TByteArray;
  bufferInitialised: boolean;

procedure initBuffer; cdecl;
begin
  if not bufferInitialised then begin
    { This throws
      "Uncaught (in promise) RuntimeError: null function or function signature mismatch"
      for some reason }
    { getmem(surface, bufferSize); }
    bufferInitialised := true
  end;
end;

function getSurface: pointer; cdecl;
begin
  getSurface := @surface
end;

procedure cls(const colour: longword); cdecl;
var
  a, r, g, b: byte;
  x, y: word;
begin
  if not bufferInitialised then exit;

  a := colour shr 24 and $FF;
  r := colour shr 16 and $FF;
  g := colour shr 8 and $FF;
  b := colour and $FF;

  for y:=0 to vgaHeight - 1 do
  for x:=0 to vgaWidth - 1 do begin
    surface[y * vgaWidth * 4 + x * 4] := r;
    surface[y * vgaWidth * 4 + x * 4 + 1] := g;
    surface[y * vgaWidth * 4 + x * 4 + 2] := b;
    surface[y * vgaWidth * 4 + x * 4 + 3] := a;
  end;
end;

{ Bitmap operations }
const
  maxImageSize = 100 * 88 * 4;

var
  imageBuffer: array[0..maxImageSize - 1] of byte;

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

procedure spr(const image: pointer; const x, y, width, height: integer);
begin

end;


exports
  initBuffer,
  getSurface,
  cls,
  { allocImageData, }
  getImageBuffer,
  spr;

begin
{ Starting point is intentionally left empty }
end.

