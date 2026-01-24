library Game;

{$Mode ObjFPC}
{$J-}

uses ItemType;

type
  TMapObjects = (
    MapObjectVoid,  { it can be either void or nothing }
    { Add more of map objects here }
    MapObjectCount
  );
  
  TMapObject = record
    active: boolean;
    flags: integer;  { Use MapObjectFlags enum }
    objectType: TMapObjects;
    itemType: TCollectibleItems;
    zone: TZone;
    imgHandle: longword;
  end;

{ Game state }
var
  mapObjects: array[0..9] of TMapObject;

function spawnMapObject(
  var mapObjects: array of TMapObject;
  const objectType: TMapObjects;
  const cx, cy: double): integer;
var
  idx: integer;
  a: word;
begin
  idx := -1;

  for a:=0 to high(mapObjects) do
    if not mapObjects[a].active then begin
      idx := a;
      break
    end;

  spawnMapObject := idx;

  if idx < 0 then exit;

  mapObjects[idx].active := true;
  mapObjects[idx].flags := 0;
  mapObjects[idx].objectType := objectType;

  mapObjects[idx].zone.x := cx;
  mapObjects[idx].zone.y := cy;
  mapObjects[idx].zone.width := 1;
  mapObjects[idx].zone.height := 1;

  mapObjects[idx].itemType := TCollectibleItems(0);

  case objectType of
    MapObjectSlimeWall: begin
      mapObjects[idx].zone.x := cx - 7;
      mapObjects[idx].zone.y := cy - 3.5;
      mapObjects[idx].zone.width := 14;
      mapObjects[idx].zone.height := 7;

      mapObjects[idx].flags := MapObjectFlagBlocking;
      mapObjects[idx].imgHandle := imgSlimeWall
    end;

    MapObjectInvisibleWall:
      mapObjects[idx].flags := MapObjectFlagBlocking;

    MapObjectLift: begin
      with mapObjects[idx].zone do begin
        width := 47;
        height := 32;
        x := cx - width / 2;
        y := cy - height / 2;
      end;

      mapObjects[idx].imgHandle := imgLift
    end;
    
    else mapObjects[idx].imgHandle := 0
  end;
end;


procedure spawnItem(
  var mapObjects: array of TMapObject;
  const itemType: TCollectibleItems;
  const cx, cy: double);
var
  idx: integer;
  imgHandle: longword;
begin
  idx := spawnMapObject(mapObjects, MapObjectItemDrop, cx, cy);
  if idx < 0 then exit;

  mapObjects[idx].flags := MapObjectFlagCollectible;
  mapObjects[idx].itemType := itemType;

  { TODO: Initialise your item zone & size here }
  mapObjects[idx].zone.x := cx - 8;
  mapObjects[idx].zone.y := cy - 4;
  mapObjects[idx].zone.width := 16;
  mapObjects[idx].zone.height := 8;

  case itemType of
    { TODO: Initialise the imgHandle and flags, if applicable }

    { Regular items }
    ItemTablet: imgHandle := imgTablet;

    { Rare items }
    ItemEgg: begin
      imgHandle := imgEgg;
      mapObjects[idx].flags := mapObjects[idx].flags or MapObjectFlagRareItem;
    end;
    else imgHandle := 0
  end;

  mapObjects[idx].imgHandle := imgHandle
end;

begin
end.
