library Game;

const
  InteractionReach = 225;  { pixels squared, not rooted }

{ Game state variables }
var
  mapObjects: array[0..4] of TMapObject;

{ Use this }
function getClosestMapObject: SmallInt;
var
  a: word;
begin
  result := -1;

  for a:=0 to high(mapObjects) do begin
    if not mapObjects[a].active then continue;

    if getZoneDist(playerZone, mapObjects[a].zone) <= InteractionReach then begin
      result := a;
      exit
    end;
  end;
end;

{ Optional: Use this if you prefer using a PMapObject }
function getClosestPMapObject: smallint;
var
  a: word;
begin
  result := -1;
  for a:=0 to high(mapObjects) do begin
    if (mapObjects[a] = nil) or not mapObjects[a]^.active then continue;

    if getZoneDist(playerZone, mapObjects[a]^.zone) <= InteractionReach then begin
      result := a;
      exit
    end;
  end;
end;

procedure update;
var
  closestMapObjectIdx: smallint;
  closestMapObject: PMapObject;
begin
  closestMapObjectIdx := getClosestMapObject;

  if lastE <> isKeyDown(SC_E) then begin
    lastE := isKeyDown(SC_E);

    if lastE then begin
      if closestMapObjectIdx >= 0 then begin
        closestMapObject := @mapObjects[closestMapObjectIdx];

        { Do something }
      end;
    end;
  end;
end;

procedure draw;
var
  a: word;
begin
  for a:=0 to high(mapObjects) do begin
    if not mapObjects[a].active then continue;

    if a = getClosestPMapObject then
      sprOutline(mapObjects[a].imgHandle,
        trunc(mapObjects[a].zone.x),
        trunc(mapObjects[a].zone.y), white)
    else
      spr(mapObjects[a].imgHandle,
        trunc(mapObjects[a].zone.x),
        trunc(mapObjects[a].zone.y));
  end;
end;

end.
