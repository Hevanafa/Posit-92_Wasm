library Game;

{$Mode ObjFPC}
{$J-}

uses
  BMFont, Conv, FPS, Fullscreen,
  Loading, Keyboard, Logger, Mouse,
  ImgRef, ImgRefFast, Panic, Shapes,
  SprEffects, Timing, WasmHeap, WasmMemMgr, VGA,
  Assets;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );

const
  SC_ESC = $01;
  SC_SPACE = $39;

  Gravity = 100;  { pixels per second squared }

  CornflowerBlue = $FF6495ED;
  DarkBlue = $FF0000AA;

type
  TParticle = record
    active: boolean;
    body: TPhysicsBody;
    imgHandle: longint;
  end;

var
  lastEsc: boolean;
  lastMouseLeft: boolean;

  { Game state variables }
  actualGameState: TGameStates;
  gameTime: double;
  particles: array[0..99] of TParticle;
  palette: array[0..4] of longword;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure loadAssets; external 'env' name 'loadAssets';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure beginLoadingState;
begin
  actualGameState := GameStateLoading;
  fitCanvas;
  loadAssets
end;

procedure beginPlayingState;
var
  a: word;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;

  { Default: cyan }
  palette[0] := $FF00BEFF;
  { red, green, yellow, magenta }
  palette[1] := $FFFF5555;
  palette[2] := $FF55FF55;
  palette[3] := $FFFFFF55;
  palette[4] := $FFFF55FF;

  writeLogI32(getFreeHeapSize);

  imgParticles[0] := imgParticle;
  for a:=1 to high(palette) do begin
    imgParticles[a] := copyImage(imgParticle);
    replaceColour(imgParticles[a], palette[0], palette[a])
  end;
end;

function EnumHasFlag(const value, flag: integer): boolean;
begin
  EnumHasFlag := 0 <> (value and flag)
end;

procedure spawnParticle(const cx, cy: integer);
var
  a, idx: integer;
begin
  idx := -1;

  for a:=0 to high(particles) do
    if not particles[a].active then begin
      idx := a;
      break
    end;

  if idx < 0 then exit;

  particles[idx].active := true;
  
  with particles[idx].body do begin
    x := cx - 3;
    y := cy - 3;
    width := 7;
    height := 7;
    vx := (random - 0.5) * 50;
    vy := -random(100);
  end;

  particles[idx].imgHandle := imgParticles[random(high(imgParticles) + 1)];
end;


procedure init;
begin
  initHeapMgr;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
begin
  beginPlayingState
end;

procedure update;
var
  a: integer;
begin
  updateDeltaTime;
  incrementFPS;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  if lastMouseLeft <> EnumHasFlag(mouseButton, MouseButtonLeft) then begin
    lastMouseLeft := EnumHasFlag(mouseButton, MouseButtonLeft);

    if lastMouseLeft then
      for a:=1 to 10 do
        spawnParticle(mouseX, mouseY);
  end;

  gameTime := gameTime + dt;

  for a:=0 to high(particles) do begin
    if not particles[a].active then continue;

    { Velocity first, then position }
    particles[a].body.vy := particles[a].body.vy + Gravity * dt;

    particles[a].body.x := particles[a].body.x + particles[a].body.vx * dt;
    particles[a].body.y := particles[a].body.y + particles[a].body.vy * dt;

    if (particles[a].body.x < -10) or (particles[a].body.x > vgaWidth)
      or (particles[a].body.y > vgaHeight) then
      particles[a].active := false;
  end;
end;

procedure draw;
var
  a: integer;
  w: integer;
  s: string;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;

  cls(DarkBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  for a:=0 to high(particles) do begin
    if not particles[a].active then continue;

    spr(
      particles[a].imgHandle,
      trunc(particles[a].body.x),
      trunc(particles[a].body.y))
  end;

  s := 'Click to spawn particles';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
  drawFPS;

  vgaFlush
end;

exports
  { Main game procedures }
  beginLoadingState,
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.

