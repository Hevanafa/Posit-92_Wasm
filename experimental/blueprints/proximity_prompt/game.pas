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

{ This requires TMapObject }
procedure ProximityPrompt(
  const letter: char;
  const cx, cy: integer;
  perc: double);
var
  s: string;
  w: word;
  x, y: double;
  endAngle: double;
begin
  perc := clamp(perc, 0.0, 1.0);
  circfillBlend(cx, cy, 7, $80454545);

  if perc > 0.0 then begin
    endAngle := lerpEaseOutQuad(0.0, 2 * pi, perc);

    arc(
      cx, cy, 7,
      -piOver2, endAngle - piOver2,
      white);
  end;

  s := letter;
  w := measureDefault(s);
  x := cx - w / 2;
  y := cy - defaultFont.lineHeight / 2;

  printDefault(s, round(x), round(y))
end;


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
  y := getZoneCY(mapObjects[lastClosestObject].zone) - 25;
  x := getZoneCX(mapObjects[lastClosestObject].zone);

  perc := holdDuration / ExpectedHoldDuration;

  ProximityPrompt('E', trunc(x + 8), trunc(y), perc);
end;

end.
