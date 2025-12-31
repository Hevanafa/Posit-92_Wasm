library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  BMFont, Graphics, Loading, Fullscreen,
  Conv, FPS, Logger,
  Keyboard, Mouse, Gamepad,
  ImgRef, ImgRefFast,
  Timing, WasmHeap, WasmMemMgr,
  PostProc, VGA,
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
  LightGrey = $FFAAAAAA;
  White = $FFFFFFFF;

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

  greyFont := defaultFont;
  greyFont.imgHandle := copyImage(defaultFont.imgHandle);
  replaceColour(greyFont.imgHandle, white, lightgrey)
end;

procedure StateLabel(const text: string; const x, y: integer; const enabled: boolean);
begin
  if enabled then
    printDefault(text, x, y)
  else
    printBMFont(greyFont, defaultFontGlyphs, text, x, y);
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
  leftX, leftY, rightX, rightY: single;
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
  end;

  { Debug buttons }
  if gamepadConnected then begin
    { if gamepadButton(BTN_DPAD_UP) then printDefault('UP', 105, 100 - 10); }
    StateLabel('UP', 95, 100 - 10, gamepadButton(BTN_DPAD_UP));
    StateLabel('DOWN', 95, 100 + 10, gamepadButton(BTN_DPAD_DOWN));
    StateLabel('LEFT', 95 - 15, 100, gamepadButton(BTN_DPAD_LEFT));
    StateLabel('RIGHT', 95 + 15, 100, gamepadButton(BTN_DPAD_RIGHT));

    StateLabel('X', 200 - 10, 100, gamepadButton(BTN_X));
    StateLabel('Y', 200, 100 - 10, gamepadButton(BTN_Y));
    StateLabel('A', 200, 100 + 10, gamepadButton(BTN_A));
    StateLabel('B', 200 + 10, 100, gamepadButton(BTN_B));

    StateLabel('LB', 145, 50, gamepadButton(BTN_LB));
    StateLabel('RB', 175, 50, gamepadButton(BTN_RB));
    StateLabel('LT', 145, 60, gamepadButton(BTN_LT));
    StateLabel('RT', 175, 60, gamepadButton(BTN_RT));

    StateLabel('START', 165, 80, gamepadButton(BTN_START));
    StateLabel('BACK', 135, 80, gamepadButton(BTN_BACK));
  end;

  { Debug analogue sticks }
  if gamepadConnected then begin
    circ(130, 150, 20, white);
    circ(190, 150, 20, white);

    leftX := gamepadAxis(AXIS_LEFT_X);
    leftY := gamepadAxis(AXIS_LEFT_Y);
    rightX := gamepadAxis(AXIS_RIGHT_X);
    rightY := gamepadAxis(AXIS_RIGHT_Y);
    circfill(130 + round(20 * leftX), 150 + round(20 * leftY), 5, white);
    circfill(190 + round(20 * rightX), 150 + round(20 * rightY), 5, white);

    StateLabel('LSTICK', 120, 180, gamepadButton(BTN_LSTICK));
    StateLabel('RSTICK', 170, 180, gamepadButton(BTN_RSTICK));

    printDefault('LX: ' + f32str(leftX), 40, 150);
    printDefault('LY: ' + f32str(leftY), 40, 160);
    printDefault('RX: ' + f32str(rightX), 220, 150);
    printDefault('RY: ' + f32str(rightY), 220, 160);
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

