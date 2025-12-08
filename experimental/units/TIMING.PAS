unit Timing;

{$Mode TP}

interface

var
  dt, lastFrameTime, currentTime: double;

{$ifdef WASM}
function getTimer: double; external 'env' name 'getTimer';
function getFullTimer: double; external 'env' name 'getFullTimer';
{$endif}
{$ifdef WIN64}
procedure initTiming;
function getMidnightOffset: double;
function getTimer: double;
function getFullTimer: double;
{$endif}

procedure initDeltaTime;
procedure updateDeltaTime;


implementation

{$ifdef WIN64}
uses SDL2Wrapper, SysUtils;
{$endif}

procedure initDeltaTime;
begin
  dt := 0.0;
  lastFrameTime := getTimer;
  currentTime := lastFrameTime;
end;

procedure updateDeltaTime;
begin
  currentTime := getTimer;
  dt := currentTime - lastFrameTime;
  lastFrameTime := currentTime
end;


{$ifdef WIN64}
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