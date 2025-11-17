unit Bitmap;

interface

type
  PBitmap = ^TBitmap;
  TBitmap = record
    width, height: word;
    data: array[0..63999] of byte;
  end;

{ Legacy }
function getImageBuffer: pointer; public name 'getImageBuffer';

function loadImageHandle: longint; public name 'loadImageHandle';
function getImagePtr(const imgHandle: longint): pointer; public name 'getImagePtr';
procedure spr(const imgHandle: longint; const x, y: integer); public name 'spr';


implementation

uses VGA;

{ Bitmap operations }
const
  maxImageBufferSize = 128 * 128 * 4;

var
  imageBuffer: array[0..maxImageBufferSize - 1] of byte;
  images: array[1..10] of TBitmap;
  nextImageHandle: longint = 1;

procedure consoleLog(value: longint); external 'env' name 'consoleLog';


function getImageBuffer: pointer;
begin
  getImageBuffer := @imageBuffer
end;

function loadImageHandle: longint;
begin
  loadImageHandle := nextImageHandle;
  inc(nextImageHandle)
end;

function getImagePtr(const imgHandle: longint): pointer;
begin
  if (1 <= imgHandle) and (imgHandle < nextImageHandle) then
    getImagePtr := @images[imgHandle]
  else
    getImagePtr := nil;
end;

procedure debugImage(const imgHandle: longint); public name 'debugImage';
var
  image: PBitmap;
  a: integer;
begin
  image := getImagePtr(imgHandle);
  if image = nil then exit;

  consoleLog(image^.width);
  consoleLog(image^.height);
  for a:=0 to 7 do
    consoleLog(image^.data[a]);
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

procedure spr(const imgHandle: longint; const x, y: integer);
var
  a, b, srcPos, destPos: integer;
  image: PBitmap;
begin
  image := getImagePtr(imgHandle);
  if image = nil then exit;

  for b:=0 to image^.height - 1 do
  for a:=0 to image^.width - 1 do begin
    srcPos := (b * image^.width + a) * 4;
    destPos := ((y + b) * vgaWidth + (x + a)) * 4;

    { Order: RGBA }
    surface[destPos] := image^.data[srcPos];
    surface[destPos + 1] := image^.data[srcPos + 1];
    surface[destPos + 2] := image^.data[srcPos + 2];
    surface[destPos + 3] := image^.data[srcPos + 3];
  end;
end;

end.
