library Game;

{$Mode ObjFPC}
{$B-}

uses
  BMFont, Conv, FPS,
  Graphics, Keyboard, Logger, Mouse,
  ImgRef, ImgRefFast, Panic, Shapes,
  Timing, WasmMemMgr, VGA,
  Assets;

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

  { Init your game state here }
  gameTime: double;
  particles: array[0..99] of TParticle;
  palette: array[0..4] of longword;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
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

procedure replaceColours(const imgHandle: longint; const oldColour, newColour: longword);
var
  a, b: word;
  image: PImageRef;
begin
  if not isImageSet(imgHandle) then begin
    writeLog('replaceColours: Unset imgHandle: ' + i32str(imgHandle));
    exit
  end;

  image := getImagePtr(imgHandle);

  for b:=0 to image^.height - 1 do
  for a:=0 to image^.width - 1 do
    if unsafeSprPget(image, a, b) = oldColour then
      unsafeSprPset(image, a, b, newColour);
end;


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
var
  a: integer;
begin
  { Initialise game state here }
  hideCursor;

  { Default: cyan }
  palette[0] := $FF00BEFF;
  { red, green, yellow, magenta }
  palette[1] := $FFFF5555;
  palette[2] := $FF55FF55;
  palette[3] := $FFFFFF55;
  palette[4] := $FFFF55FF;

  imgParticles[0] := imgParticle;
  for a:=1 to high(palette) do begin
    imgParticles[a] := copyImage(imgParticle);
    replaceColours(imgParticles[a], palette[0], palette[a])
  end;
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
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

