library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  IntroScr, Loading, Fullscreen,
  Conv, FPS, Logger,
  Keyboard, Mouse, Gamepad,
  ImgRef, ImgRefFast,
  Timing, WasmHeap, WasmMemMgr,
  VGA,
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
  SC_ENTER = $1C;

  CornflowerBlue = $FF6495ED;

var
  lastEsc: boolean;

  { Init your game state here }
  actualGameState: TGameStates;
  gameTime: double;


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
end;


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
  initFPSCounter
end;

procedure afterInit;
begin
  beginPlayingState
end;

procedure update;
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

  { Handle game state updates }
  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
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

  if not gamepadConnected then begin
    s := 'Plug in a controller';
    w := measureDefault(s);
    printDefault(s, (vgaWidth - w) div 2, 120);
  end else begin
    s := 'Press any gamepad key';
    w := measureDefault(s);
    printDefault(s, (vgaWidth - w) div 2, 120);
  end;

  if gamepadConnected then begin
    if gamepadButton(BTN_X) then printDefault('X', 10, 20);
    if gamepadButton(BTN_Y) then printDefault('Y', 20, 10);
    if gamepadButton(BTN_A) then printDefault('A', 20, 30);
    if gamepadButton(BTN_B) then printDefault('B', 30, 20);

    if gamepadButton(BTN_LB) then printDefault('LB', 10, 50);
    if gamepadButton(BTN_RB) then printDefault('RB', 30, 50);
    if gamepadButton(BTN_LT) then printDefault('LT', 10, 60);
    if gamepadButton(BTN_RT) then printDefault('RT', 30, 60);

    if gamepadButton(BTN_DPAD_UP) then printDefault('UP', 10, 80);
    if gamepadButton(BTN_DPAD_DOWN) then printDefault('DOWN', 10, 90);
    if gamepadButton(BTN_DPAD_LEFT) then printDefault('LEFT', 10, 100);
    if gamepadButton(BTN_DPAD_RIGHT) then printDefault('RIGHT', 10, 110);

    if gamepadButton(BTN_START) then printDefault('START', 10, 80);
    if gamepadButton(BTN_BACK) then printDefault('BACK', 10, 80);

    if gamepadButton(BTN_LSTICK) then printDefault('LSTICK', 75, 100);
    if gamepadButton(BTN_RSTICK) then printDefault('RSTICK', 75, 120);

    printDefault('LX: ' + f32str(gamepadAxis(AXIS_LEFT_X)), 10, 100);
    printDefault('LY: ' + f32str(gamepadAxis(AXIS_LEFT_Y)), 10, 110);

    printDefault('RX: ' + f32str(gamepadAxis(AXIS_RIGHT_X)), 10, 120);
    printDefault('RY: ' + f32str(gamepadAxis(AXIS_RIGHT_Y)), 10, 130);
  end;

  drawMouse;
  drawFPS;

  vgaFlush
end;

exports
  beginLoadingState,
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

