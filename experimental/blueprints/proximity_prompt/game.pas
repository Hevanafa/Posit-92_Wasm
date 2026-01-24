{
  Proximity Prompt Blueprint
  Part of Posit-92 Engine

  This demonstrates how to:
  - Implement hold duration
  - Closest object search throttling (18 Hz)
}

library Game;

{$Mode ObjFPC}
{$J-}

const
  ExpectedHoldDuration = 2.5;  { in seconds }

var
  { Map object interaction }
  holdDuration: double;
  lastClosestObject: integer;  { index of map object }
  nextClosestObjectTick: double;  { use gameTime }


procedure initPlayingState;
begin
  holdDuration := 0.0;
  lastClosestObject := -1;
  nextClosestObjectTick := 0.0;
end;

procedure update;
begin
  if gameTime >= nextClosestObjectTick then begin
    closestObject := -1;
    closestDist := 99999;

    for a:=0 to high(mapObjects) do begin
      if not mapObjects[a].active then continue;

      { TODO: Add the interaction flags / conditions }

      dist := getZoneDist(physicsBodyToZone(player.body), mapObjects[a].zone);
      if (dist <= PickupReach) and (dist < closestDist) then begin
        closestObject := a;
        closestDist := dist;
      end;
    end;

    if lastClosestObject <> closestObject then begin
      lastClosestObject := closestObject;
      holdDuration := 0.0;
      nextClosestObjectTick := gameTime + 1 / 18.0
    end;
  end;

  if lastClosestObject <> -1 then begin
    if isKeyDown(SC_E) then begin
      holdDuration := holdDuration + dt;

      if holdDuration >= ExpectedHoldDuration then begin
        dist := getZoneDist(
          physicsBodyToZone(player.body),
          mapObjects[lastClosestObject].zone);

        if dist <= PickupReach then begin
          mapObjects[lastClosestObject].active := false;

          { TODO: On successful prompt }
        end;
      end;
    end;
  end;

  { Handle early release }
  if lastE <> isKeyDown(SC_E) then begin
    lastE := isKeyDown(SC_E);

    if not lastE then holdDuration := 0.0;
  end;
end;


procedure draw;
var
  x, y: double;
begin
  if lastClosestObject <> -1 then begin
    { TODO: Fill x & y to where you want your prompt }

    { Show prompt }
    printDefault('E', trunc(x), trunc(y));

    { Optional: show progress }
    if holdDuration > 0 then begin
      perc := holdDuration / ExpectedHoldDuration;

      { Render your progress indicator }
    end;
  end;
end;

end.
