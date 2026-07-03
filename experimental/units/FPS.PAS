{
  FPS unit - Part of Posit-92 game engine
  Hevanafa

  Mandatory for FPS (frames per second) counting
}

unit FPS;

{$Mode ObjFPC}
{$H+}{$J-}
{/$Define Debug}

interface

procedure InitFPSCounter;
procedure IncrementFPS;

function GetLastFPS: smallint;
procedure DrawFPS;

implementation

uses
  P92Core, Conv, P92Timing, VGA;

var
  actualFPS, lastFPS: smallint;
  lastFPSTime: double; { in seconds }

procedure InitFPSCounter;
begin
  actualFPS := 0;
  lastFPS := 0;
  lastFPSTime := GetTimer;
end;

procedure IncrementFPS;
begin
  actualFPS := actualFPS + 1;
  if getTimer - lastFPSTime >= 1.0 then begin
    lastFPSTime := getTimer;
    lastFPS := actualFPS;
    actualFPS := 1
  end;
end;

function GetLastFPS: smallint;
begin
  GetLastFPS := lastFPS
end;

procedure DrawFPS;
begin
  print('FPS: ' + i32str(GetLastFPS), VgaWidth - 100, 0);

{$ifdef debug}
  print('lastFPS: ' + i32str(lastFPS), VgaWidth - 160, 16);
  print('actualFPS: ' + i32str(actualFPS), VgaWidth - 160, 24);
  print('lastFPSTime: ' + f32str(lastFPSTime), VgaWidth - 160, 32);
{$endif}
end;

end.

