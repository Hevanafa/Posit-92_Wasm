library Game;

procedure updatePhysicsBody(var body: TPhysicsBody);  { const dt: double }
begin
  body.x := body.x + body.vx;
  body.y := body.y + body.vy;
end;

procedure checkMapObjectCollisions(var body: TPhysicsBody; const mapObjects: array of TMapObject);
var
  a: word;
  bodyZone: TZone;
  testBody: TPhysicsBody;
begin
  { Predict Y then X }

  { Check Y }
  testBody := body;
  testBody.y := testBody.y + testBody.vy;

  for a:=0 to high(mapObjects) do begin
    if not mapObjects[a].active then continue;
    if not EnumHasFlag(mapObjects[a].flags, MapObjectFlagBlocking) then continue;

    bodyZone := physicsBodyToZone(testBody);
    if zoneIntersects(bodyZone, mapObjects[a].zone) then begin
      if testBody.vy > 0 then
        testBody.y := mapObjects[a].zone.y - testBody.height;
      if testBody.vy < 0 then
        testBody.y := mapObjects[a].zone.y + mapObjects[a].zone.height;

      testBody.vy := 0.0;
      break
    end;
  end;
  body := testBody;  { Commit }

  { Check X }
  testBody := body;
  testBody.x := testBody.x + testBody.vx;

  for a:=0 to high(mapObjects) do begin
    if not mapObjects[a].active then continue;
    if not EnumHasFlag(mapObjects[a].flags, MapObjectFlagBlocking) then continue;

    bodyZone := physicsBodyToZone(testBody);
    if zoneIntersects(bodyZone, mapObjects[a].zone) then begin
      if testBody.vx > 0 then
        testBody.x := mapObjects[a].zone.x - testBody.width;
      if testBody.vx < 0 then
        testBody.x := mapObjects[a].zone.x + mapObjects[a].zone.width;

      testBody.vx := 0.0;
      break
    end;
  end;
  body := testBody;  { Commit }
end;

procedure clampPhysicsBodyToBounds(var body: TPhysicsBody; const bounds: TZone);
begin
  if body.x < bounds.x then body.x := bounds.x;
  if body.y < bounds.y then body.y := bounds.y;

  if body.x + body.width >= bounds.x + bounds.width then
    body.x := bounds.x + bounds.width - body.width;
  if body.y + body.height >= bounds.y + bounds.height then
    body.y := bounds.y + bounds.height - body.height;
end;


procedure update;
begin
  { TODO: Handle movement update }
  checkMapObjectCollisions(player.body, mapObjects);
  clampPhysicsBodyToBounds(player.body, mapBounds);
end;


begin
end.