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
function getTimer: double;
function getFullTimer: double;
{$endif}

procedure initDeltaTime;
procedure updateDeltaTime;


implementation

{$ifdef WIN64}
uses SDL2Wrapper;
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
  perfFrequency: int64;
  startCounter: int64;

procedure initTiming;
begin
  perfFrequency := SDL_GetPerformanceFrequency;
  startCounter := SDL_GetPerformanceCounter;
  timingInitialised := true
end;

function getTimer: double;
var
  now: int64;
begin
  if not timingInitialised then initTiming;
  now := SDL_GetPerformanceCounter;
  getTimer := (now - startCounter) / perfFrequency
end;

function getFullTimer: double;
begin
  if not timingInitialised then initTiming;
  getFullTimer := SDL_GetPerformanceCounter / perfFrequency
end;
{$endif}


end.