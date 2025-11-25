{
  Timing unit
  Part of Posit-92 framework
  By Hevanafa
  Update 25-11-2025
}

unit Timing;

{$Mode TP}

interface

var
  dt, lastFrameTime, currentTime: double;

function getTimer: double; external 'env' name 'getTimer';
function getFullTimer: double; external 'env' name 'getFullTimer';

procedure initDeltaTime;
procedure updateDeltaTime;


implementation

procedure initDeltaTime;
begin
  dt := 0;
  lastFrameTime := getTimer;
  currentTime := lastFrameTime;
end;

procedure updateDeltaTime;
begin
  currentTime := getTimer;
  dt := currentTime - lastFrameTime;
  lastFrameTime := currentTime
end;

end.