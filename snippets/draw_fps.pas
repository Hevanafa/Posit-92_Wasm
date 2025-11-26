{ Step 1: Include the FPS unit }
uses FPS;

{ Step 2: add this in the update logic }
incrementFPS;

{ Step 3: add this in game.pas }
procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

{ Step 4: call this before flush }
drawFPS;
