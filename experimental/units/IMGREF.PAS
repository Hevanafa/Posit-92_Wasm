unit ImgRef;

interface

type
  PImageRef = ^TImageRef;
  TImageRef = record
    { handle: longint; }  { Index on JS }
    dataPtr: pointer;
    width: integer;
    height: integer;
  end;

procedure registerImageRef(const handle: longint; const dataPtr: pointer; const w, h: integer); public name 'registerImageRef';
function getImageRefPtr(const handle: integer): PImageRef;
{ function getImageRefCount: integer; }

{ spr with TImageRef }
procedure sprRef(const handle: longint; const x, y: integer);


implementation

uses Logger, Panic, VGA;

const
  MaxImageRefs = 256;

var
  imageRefs: array[1..MaxImageRefs] of TImageRef;
  { imageRefCount: integer = 0; }

  { Debug variables }
  sprRefOnceA, sprRefOnceB: boolean;


function isImageSet(const imgHandle: longint): boolean;
begin
  isImageSet := (imageRefs[imgHandle].width > 0) and (imageRefs[imgHandle].height > 0)
end;

function findEmptyImageRefSlot: integer;
var
  a: longint;
begin
  for a:=1 to high(imageRefs) do
    if not isImageSet(a) then begin
      findEmptyImageRefSlot := a;
      exit
    end;

  findEmptyImageRefSlot := -1
end;

procedure registerImageRef(const handle: longint; const dataPtr: pointer; const w, h: integer);
var
  idx: integer;
  testByte: PByte;
begin
  idx := findEmptyImageRefSlot;

  { if imageRefCount >= MaxImageRefs then }
  if idx < 0 then
    panicHalt('Image ref pool is full!');

  writeLog('registerImageRef: handle, w, h');
  writeLogI32(handle);
  writeLogI32(w);
  writeLogI32(h);

  { imageRefs[handle].handle := handle; }
  imageRefs[handle].dataPtr := dataPtr;

  testByte := PByte(dataPtr);
  writeLog('dataPtr[0]:');
  writeLogI32(testByte[0]);

  imageRefs[handle].width := w;
  imageRefs[handle].height := h;

  writeLog('imageRefs[handle]: handle, width, height');
  writeLogI32(handle);
  with imageRefs[handle] do begin
    writeLogI32(width);
    writeLogI32(height);
  end;

  { inc(imageRefCount) }
end;

function getImageRefPtr(const handle: integer): PImageRef;
begin
  getImageRefPtr := @imageRefs[handle]
end;

{
function getImageRefCount: integer;
begin
  getImageRefCount := imageRefCount
end;
}

{ Render procedures }
procedure sprRef(const handle: longint; const x, y: integer);
var
  ref: PImageRef;
  px, py: integer;
  offset: longword;
  data: PByte;
  r, g, b, a: byte;
  colour: longword;
begin
  if not sprRefOnceA then begin
    writeLog('sprRef handle');
    writeLogI32(handle);
    sprRefOnceA := true
  end;

  { if (handle < 1) or (handle >= getImageRefCount) then exit; }
  { TODO: Handle if image is set }

  ref := getImageRefPtr(handle);

  data := PByte(ref^.dataPtr);

  if not sprRefOnceB then begin
    writeLog('Got image ref');
    writeLogI32(ref^.width);
    writeLogI32(ref^.height);

    writeLog('First 20 bytes of data');
    for px:=0 to 19 do
      writeLogI32(data[px]);

    sprRefOnceB := true
  end;

  for py:=0 to ref^.height - 1 do
  for px:=0 to ref^.width - 1 do begin
    if (x + px >= vgaWidth) or (x + px < 0)
      or (y + py >= vgaHeight) or (y + py < 0) then continue;

    { offset to ImageData buffer }
    offset := (px + py * ref^.width) * 4;

    r := data[offset];
    g := data[offset + 1];
    b := data[offset + 2];
    a := data[offset + 3];

    if a < 255 then continue;

    colour := (a shl 24) or (r shl 16) or (g shl 8) or b;
    unsafePset(x + px, y + py, colour)
  end;
end;

end.

