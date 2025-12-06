library Game;

{$Mode TP}

uses
  Keyboard, Mouse,
  Conv, ImgRef, ImgRefFast, Maths,
  PostProc, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  SC_BACKSPACE = $0E;

  SC_LEFT = $4B;
  SC_RIGHT = $4D;
  SC_UP = $48;
  SC_DOWN = $50;


var
  lastEsc, lastBackspace: boolean;
  lastUp, lastDown: boolean;

  { Init your game state here }
  gameTime: double;

  actualFalloffType: FalloffTypes;
  vignetteStrength: double;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure resetParameters;
begin
  actualFalloffType := FalloffTypes(0);
  vignetteStrength := 0.3;
end;


procedure init;
begin
  initBuffer;
  initDeltaTime;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;

  resetParameters;
end;

procedure update;
begin
  updateDeltaTime;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then signalDone;
  end;

  if lastBackspace <> isKeyDown(SC_BACKSPACE) then begin
    lastBackspace := isKeyDown(SC_BACKSPACE);
    if lastBackspace then resetParameters;
  end;

  if isKeyDown(SC_LEFT) then
    vignetteStrength := vignetteStrength - dt / 2;
  
  if isKeyDown(SC_RIGHT) then
    vignetteStrength := vignetteStrength + dt / 2;

  if lastUp <> isKeyDown(SC_UP) then begin
    lastUp := isKeyDown(SC_UP);
    if lastUp then dec(actualFalloffType);
  end;

  if lastDown <> isKeyDown(SC_DOWN) then begin
    lastDown := isKeyDown(SC_DOWN);
    if lastDown then inc(actualFalloffType);
  end;

  if ord(actualFalloffType) < 0 then
    actualFalloffType := FalloffTypes(ord(FalloffTypeCount) - 1);
  if ord(actualFalloffType) >= ord(FalloffTypeCount) then
    actualFalloffType := FalloffTypes(0);

  vignetteStrength := clamp(vignetteStrength, 0.0, 1.0);

  gameTime := gameTime + dt
end;

procedure draw;
var
  s: string;
  w: word;
begin
  cls($FF6495ED);

  spr(imgArkRoad, 0, 0);

  applyFullVignette(actualFalloffType, vignetteStrength);

  printDefault('Falloff: ' + getFalloffName(actualFalloffType) + ' (' + i32str(ord(actualFalloffType)) + ')', 10, vgaHeight - 60);
  printDefault('Strength: ' + f32str(vignetteStrength), 10, vgaHeight - 50);

  printDefault('Left / right: Adjust strength', 10, vgaHeight - 30);
  printDefault('Up / down: Toggle falloff', 10, vgaHeight - 20);

  s := 'Art by Kevin Hong';
  w := measureDefault(s);
  printDefault(s, vgaWidth - w - 10, vgaHeight - 20);

  drawMouse;
  flush
end;

exports
  { Main game procedures }
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

