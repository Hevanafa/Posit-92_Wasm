library Game;

{$Mode ObjFPC}

uses
  Conv, FPS, Graphics,
  ImgRef, ImgRefFast, Keyboard, Logger, Mouse,
  Panic, Sounds, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  SC_1 = $02;
  SC_2 = $03;
  SC_3 = $04;
  SC_4 = $05;
  SC_5 = $06;

var
  lastEsc, lastSpacebar: boolean;
  lastD1, lastD2, lastD3, lastD4, lastD5: boolean;

  { Init your game state here }
  gameTime: double;

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

procedure playRandomSFX;
begin
  playSound(1 + random(SfxSlip))
end;


procedure init;
begin
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;
end;

procedure update;
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

  if lastSpacebar <> isKeyDown(SC_SPACE) then begin
    lastSpacebar := isKeyDown(SC_SPACE);

    if lastSpacebar then playRandomSFX;
  end;

  if lastD1 <> isKeyDown(SC_1) then begin
    lastD1 := isKeyDown(SC_1);
    if lastD1 then playSound(1);
  end;

  if lastD2 <> isKeyDown(SC_2) then begin
    lastD2 := isKeyDown(SC_2);
    if lastD2 then playSound(2);
  end;

  if lastD3 <> isKeyDown(SC_3) then begin
    lastD3 := isKeyDown(SC_3);
    if lastD3 then playSound(3);
  end;

  if lastD4 <> isKeyDown(SC_4) then begin
    lastD4 := isKeyDown(SC_4);
    if lastD4 then playSound(4);
  end;

  if lastD5 <> isKeyDown(SC_5) then begin
    lastD5 := isKeyDown(SC_5);
    if lastD5 then playSound(5);
  end;

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := '1, 2, 3, 4, 5 - Play sound';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  s := 'Spacebar - Play a random sound';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 130);

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

