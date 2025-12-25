library Game;

{$Mode ObjFPC}

uses
  Conv, FPS, Loading, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Timing, WasmMemMgr, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawFPS;
begin
  printDOS('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit; public name 'afterInit';
begin
  { Initialise game state here }
  hideCursor;
  { replaceColours(defaultFont.imgHandle, $FFFFFFFF, $FF000000); }
end;

procedure update; public name 'update';
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

  gameTime := gameTime + dt
end;

procedure draw; public name 'draw';
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  { Your drawing code here }

  drawMouse;
  drawFPS;

  vgaFlush
end;

{ Requires at least 1 exported member }
exports init;

begin
{ Starting point is intentionally left empty }
end.

