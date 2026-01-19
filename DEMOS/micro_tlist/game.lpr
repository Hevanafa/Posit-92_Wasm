library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  Loading, Fullscreen,
  Conv, FPS, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast, List,
  Timing, WasmMemMgr, VGA,
  Assets;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );

  PFirefly = ^TFirefly;
  TFirefly = record
    alive: boolean;
    x, y: double;
  end;

const
  SC_ESC = $01;
  SC_SPACE = $39;
  SC_ENTER = $1C;
  SC_BACKSPACE = $0E;

  CornflowerBlue = $FF6495ED;

var
  lastEsc: boolean;
  lastSpacebar, lastBackspace: boolean;

  { Game state variables }
  actualGameState: TGameStates;
  gameTime: double;

  fireflyList: TList;


{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure hideCursor; external 'env' name 'hideCursor';
procedure hideLoadingOverlay; external 'env' name 'hideLoadingOverlay';
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
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;

  randseed := trunc(getTimer);

  fireflyList.init;
end;


procedure init;
begin
  initHeapMgr;
  initDeltaTime;
  initFPSCounter
end;

procedure afterInit;
begin
  beginPlayingState
end;

procedure update;
var
  f: PFirefly;
begin
  updateDeltaTime;
  incrementFPS;

  { Handle inputs }
  updateMouse;

  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  if lastSpacebar <> isKeyDown(SC_SPACE) then begin
    lastSpacebar := isKeyDown(SC_SPACE);

    if lastSpacebar then begin
      new(f);

      f^.alive := true;
      f^.x := 20 + random(vgaWidth - 40);
      f^.y := 20 + random(vgaHeight - 40);

      fireflyList.push(f)
    end;
  end;

  if lastBackspace <> isKeyDown(SC_BACKSPACE) then begin
    lastBackspace := isKeyDown(SC_BACKSPACE);

    if lastBackspace then begin
      f := fireflyList.pop;

      if f <> nil then dispose(f);
    end;
  end;

  { Handle game state updates }
  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
  a: word;
  f: PFirefly;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;

  cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  if fireflyList.length > 0 then
    for a:=0 to fireflyList.length - 1 do begin
      f := fireflyList.get(a);
      if not f^.alive then continue;

      spr(imgDosuEXE[0], trunc(f^.x), trunc(f^.y))
    end;

  s := 'Spacebar - Spawn more | Backspace - Remove last';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
  drawFPS;

  vgaFlush
end;

exports
  beginLoadingState,
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.


