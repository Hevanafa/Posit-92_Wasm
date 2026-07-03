{
  Timing unit - Part of Posit-92 game engine
  Hevanafa
}

unit P92Timing;

{$Mode ObjFPC}
{$H+}{$J-}

interface

function DeltaTime: double;

{$ifdef WASM}
function GetTimer: double; external 'env' name 'GetTimer';
function GetFullTimer: double; external 'env' name 'GetFullTimer';
{$endif}

{$ifdef Windows}
procedure initTiming;
function getMidnightOffset: double;
function getTimer: double;
function getFullTimer: double;
{$endif}

procedure InitDeltaTime;
procedure UpdateDeltaTime;


implementation

{$ifdef Windows}
uses SDL2Wrapper, SysUtils;
{$endif}

var
  dt, lastFrameTime, currentTime: double;

function DeltaTime: double;
begin
  DeltaTime := dt
end;

procedure InitDeltaTime;
begin
  dt := 0.0;
  lastFrameTime := GetTimer;
  currentTime := lastFrameTime;
end;

procedure UpdateDeltaTime;
begin
  currentTime := GetTimer;
  dt := currentTime - lastFrameTime;
  lastFrameTime := currentTime
end;


{$ifdef Windows}
var
  timingInitialised: boolean;
  midnightOffset: double;  { Offset from midnight the day when the app started }
  epochStart: TDateTime;

procedure initTiming;
begin
  epochStart := EncodeDate(1970, 1, 1);
  midnightOffset := trunc(now);
  timingInitialised := true
end;

function getMidnightOffset: double;
begin
  getMidnightOffset := midnightOffset
end;

{ Returns the time in seconds }
function getTimer: double;
begin
  if not timingInitialised then initTiming;
  getTimer := frac(now - midnightOffset) * 86400.0
end;

{ Returns the time in seconds since epoch }
function getFullTimer: double;
begin
  if not timingInitialised then initTiming;
  getFullTimer := (now - epochStart) * 86400.0
end;
{$endif}


end.
