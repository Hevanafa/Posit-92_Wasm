{ Step 1: Include the FPS unit }
uses
  Conv, FPS;

{ Step 2: Add these lines in init }
initDeltaTime;
initFPSCounter;

{ Step 3: Add these lines in the update logic }
updateDeltaTime;
incrementFPS;

{ Step 4: add this in game.pas }
procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

{ Step 5: call this before flush }
drawFPS;
