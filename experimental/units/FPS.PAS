unit FPS;

{$Mode TP}

interface

procedure initFPSCounter;
procedure incrementFPS;
{ procedure drawFPS; }

function getLastFPS: integer;


implementation

uses
  Conv, Timing, VGA;

var
  actualFPS, lastFPS: integer;
  lastFPSTime: double; { in seconds }

procedure initFPSCounter;
begin
  actualFPS := 0;
  lastFPS := 0;
  lastFPSTime := getTimer;
end;

procedure incrementFPS;
begin
  actualFPS := actualFPS + 1;
  if getTimer - lastFPSTime >= 1.0 then begin
    lastFPSTime := getTimer;
    lastFPS := actualFPS;
    actualFPS := 1
  end;
end;

function getLastFPS: integer;
begin
  getLastFPS := lastFPS
end;


end.