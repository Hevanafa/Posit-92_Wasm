library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

const
  SC_W = $11;
  SC_A = $1E;
  SC_S = $1F;
  SC_D = $20;

  Velocity = 100;  { pixels per second }


{ Game state }
var
  playerZone: TZone;


procedure beginPlayingState;
begin
  playerZone.x := 100;
  playerZone.y := 100;
  playerZone.width := 12;
  playerZone.height := 8;
end;


procedure update;
begin
  updateDeltaTime;

  if isKeyDown(SC_W) then playerZone.y := playerZone.y - Velocity * dt;
  if isKeyDown(SC_S) then playerZone.y := playerZone.y + Velocity * dt;
  if isKeyDown(SC_A) then playerZone.x := playerZone.x - Velocity * dt;
  if isKeyDown(SC_D) then playerZone.x := playerZone.x + Velocity * dt;
end;


procedure draw;
begin
  drawZone(playerZone, white);
end;


begin
{ Starting point is intentionally left empty }
end.
