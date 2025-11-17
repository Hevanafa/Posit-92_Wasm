library Game;

{$Mode ObjFPC}

uses Bitmap, VGA;

var
  loadedImage: TBitmap;

function getLoadedImage: pointer; public name 'getLoadedImage';
begin
  getLoadedImage := @loadedImage
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

