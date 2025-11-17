library Game;

{$Mode ObjFPC}

uses Bitmap, VGA;

var
  images: array[1..10] of TBitmap;
  nextImageHandle: longint = 1;

function getImagePtr(const imgHandle: longint): pointer; public name 'getImagePtr';
begin
  if (1 <= imgHandle) and (imgHandle < nextImageHandle) then
    getImagePtr := @images[imgHandle]
  else
    getImagePtr := nil;
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

