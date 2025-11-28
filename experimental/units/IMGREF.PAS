unit ImgRef;

{$Mode TP}
{$H-}

interface

type
  PImageRef = ^TImageRef;
  TImageRef = record
    width: integer;
    height: integer;
    dataPtr: PByte;
  end;

procedure registerImageRef(const imgHandle: longint; const dataPtr: PByte; const w, h: integer); public name 'registerImageRef';
function getImageRefPtr(const imgHandle: longint): PImageRef;

function getImageWidth(const imgHandle: longint): word;
function getImageHeight(const imgHandle: longint): word;


{ spr with TImageRef }
procedure sprRef(const imgHandle: longint; const x, y: integer);


implementation

uses Logger, Panic, VGA;

const
  MaxImageRefs = 256;

var
  imageRefs: array[1..MaxImageRefs] of TImageRef;


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

procedure registerImageRef(const imgHandle: longint; const dataPtr: PByte; const w, h: integer);
var
  idx: integer;
  testByte: PByte;
begin
  idx := findEmptyImageRefSlot;

  if idx < 0 then
    panicHalt('Image ref pool is full!');

  imageRefs[imgHandle].width := w;
  imageRefs[imgHandle].height := h;
  imageRefs[imgHandle].dataPtr := dataPtr;

  { Removing this crashes the program for some reason }
  testByte := PByte(dataPtr);
  writeLog('dataPtr[0]:');
  writeLogI32(testByte[0]);

  { Removing this crashes the program for some reason }
  writeLog('imageRefs[imgHandle]: imgHandle, width, height');
  writeLogI32(imgHandle);
  with imageRefs[imgHandle] do begin
    writeLogI32(width);
    writeLogI32(height);
  end;
end;

function getImageRefPtr(const imgHandle: longint): PImageRef;
begin
  getImageRefPtr := @imageRefs[imgHandle]
end;

function getImageWidth(const imgHandle: longint): word;
var
  image: PImageRef;
begin
  getImageWidth := 0;
  if not isImageSet(imgHandle) then exit;

  image := getImageRefPtr(imgHandle);
  getImageWidth := image^.width
end;

function getImageHeight(const imgHandle: longint): word;
var
  image: PImageRef;
begin
  getImageHeight := 0;
  if not isImageSet(imgHandle) then exit;

  image := getImageRefPtr(imgHandle);
  getImageHeight := image^.height
end;

{ Render procedures }

procedure sprRef(const imgHandle: longint; const x, y: integer);
var
  ref: PImageRef;
  px, py: integer;
  offset: longword;
  data: PByte;
  r, g, b, a: byte;
  colour: longword;
begin
  if not isImageSet(imgHandle) then exit;

  ref := getImageRefPtr(imgHandle);
  data := PByte(ref^.dataPtr);

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

