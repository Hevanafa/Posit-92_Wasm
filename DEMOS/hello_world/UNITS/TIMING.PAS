unit Timing;

{$Mode TP}

interface

var
  dt, lastFrameTime, currentTime: double;

function getTimer: double; external 'env' name 'getTimer';

procedure initDeltaTime; public name 'initDeltaTime';
procedure updateDeltaTime; public name 'updateDeltaTime';


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