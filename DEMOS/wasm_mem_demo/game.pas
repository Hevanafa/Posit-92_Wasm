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
  SC_C = $2E;
  SC_V = $2F;

type
  PItem = ^TItem;
  TItem = record
    active: boolean;
    itemType: integer;
    count: integer;
  end;

var
  lastEsc: boolean;
  lastZ, lastX, lastC, lastV: boolean;

  { Init your game state here }
  gameTime: double;

  items: array[0..9] of PItem;
  itemCount: integer;

  buffer: PByte;
  bufferSize: integer;

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
  hideCursor;

  { Initialise game state here }
  gameTime := 0.0;
  for a:=0 to high(items) do items[a] := nil;
  itemCount := 0;

  buffer := nil;
  bufferSize := 0;

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
    
    if lastZ and (itemCount < length(items)) then begin
      { Push item }
      items[itemCount] := new(PItem);
      with items[itemCount]^ do begin
        active := false;
        itemType := 0;
        count := 0;
      end;
      inc(itemCount)
    end;
  end;

  if lastX <> isKeyDown(SC_X) then begin
    lastX := isKeyDown(SC_X);

    if lastX and (itemCount > 0) then begin
      { Pop item }
      dispose(items[itemCount-1]);
      items[itemCount-1] := nil;
      dec(itemCount)
    end;
  end;

  if lastC then begin
    { Grow buffer size }
    lastC := isKeyDown(SC_C);

    if lastC then begin
      if buffer = nil then
        bufferSize := 10
      else
        bufferSize := bufferSize + 10;

      buffer := ReallocMem(buffer, bufferSize)
      { TODO: Fill with test data }
    end;
  end;

  if lastV then begin
    { Shrink or free }
    lastV := isKeyDown(SC_V);

    if bufferSize > 10 then begin
      dec(bufferSize, 10);
      buffer := ReallocMem(buffer, bufferSize)
    end else begin
      buffer := ReallocMem(buffer, 0);
      bufferSize := 0
    end;;
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

  printDefault('Buffer size: ' + i32str(bufferSize), 10, 50);

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

