library Game;

{$Mode ObjFPC}
{$B-}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, Keyboard, Logger, Mouse,
  Panic, Shapes, Sounds, Timing, VGA,
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
    zone: TRect;
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
  
  particles[idx].zone := newRect(cx - 3, cy - 3, 7, 7);
  particles[idx].zone.vx := (random - 0.5) * 50;
  particles[idx].zone.vy := -random(100);

  particles[idx].imgHandle := imgParticles[random(high(imgParticles) + 1)];
end;

procedure replaceColours(const imgHandle: longint; const oldColour, newColour: longword);
var
  a, b: word;
  image: PBitmap;
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
    particles[a].zone.vy := particles[a].zone.vy + Gravity * dt;

    particles[a].zone.x := particles[a].zone.x + particles[a].zone.vx * dt;
    particles[a].zone.y := particles[a].zone.y + particles[a].zone.vy * dt;

    if (particles[a].zone.x < 10) or (particles[a].zone.x > vgaWidth)
      or (particles[a].zone.y > vgaHeight) then
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
      trunc(particles[a].zone.x),
      trunc(particles[a].zone.y))
  end;

  s := 'Click to spawn particles';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
  drawFPS;

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

