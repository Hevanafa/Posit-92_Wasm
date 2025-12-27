library Game;

{$Mode TP}

uses
  Conv, FPS, Loading, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  PostProc, Timing,
  WasmHeap, WasmMemMgr, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  SC_Z = $2C;
  SC_X = $2D;

type
  PItem = ^TItem;
  TItem = record
    active: boolean;
    itemType: integer;
    count: integer;
  end;

var
  lastEsc: boolean;
  lastZ, lastX: boolean;

  { Init your game state here }
  gameTime: double;

  items: array[0..9] of PItem;
  itemCount: integer;

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


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;

  { replaceColours(defaultFont.imgHandle, $FFFFFFFF, $FF000000); }
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

  if lastZ <> isKeyDown(SC_Z) then begin
    lastZ := isKeyDown(SC_Z);
    
    if lastZ then begin
      items[itemCount] := new(PItem);
      inc(itemCount)
    end;
  end;

  if lastX <> isKeyDown(SC_X) then begin
    lastX := isKeyDown(SC_X);

    if lastX and (itemCount > 0) then begin
      dispose(items[itemCount-1]);
      items[itemCount-1] := nil;
      dec(itemCount)
    end;
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

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  printDefault('Mem usage: ' + i32str(getHeapSize - getFreeHeapSize) + ' / ' + i32str(getHeapSize) + ' B', 10, 10);

  printDefault('Item count: ' + i32str(itemCount), 10, 30);

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

