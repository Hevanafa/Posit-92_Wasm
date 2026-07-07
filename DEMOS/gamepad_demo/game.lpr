library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  P92Core, P92Fonts, P92WasmHost,
  P92BMFont, P92Graphics, P92Loading,
  P92Conversions, P92FPS, P92Logger,
  P92Keyboard, P92Mouse, Gamepad,
  P92Tex, P92TexDraw, P92TexEffects,
  P92Timing, P92VGA,
  Assets;

const
  CornflowerBlue = $FF6495ED;
  LightGrey = $FFAAAAAA;
  White = $FFFFFFFF;
  Green = $FF55FF55;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;


procedure DrawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure OnPreload;
begin
  { TODO: List the assets to load }
end;

procedure BeginPlayingState;
begin
  HideCursor;
  FitCanvas;

  { Initialise game state here }
  gameTime := 0.0;

  greyFont := DefaultFontPtr^;
  greyFont.texHandle := CopyTexture(DefaultFontPtr^.texHandle);
  replaceColour(greyFont.texHandle, white, lightgrey)
end;

procedure StateLabel(const text: string; const x, y: integer; const enabled: boolean);
begin
  if enabled then
    PrintDefault(text, x, y)
  else
    PrintBMFont(greyFont, DefaultFontGlyphsPtr^, text, x, y);
end;


procedure OnReady;
begin
  BeginPlayingState
end;

procedure Update;
begin
  UpdateDeltaTime;
  IncrementFPS;

  { Handle inputs }
  UpdateMouse;

  if lastEsc <> isKeyDown(SC_ESCAPE) then begin
    lastEsc := isKeyDown(SC_ESCAPE);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  { Handle game state updates }
  gameTime := gameTime + DeltaTime
end;

procedure Draw;
var
  w: integer;
  s: string;
  leftX, leftY, rightX, rightY: single;
begin
  cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  if not GamepadConnected then begin
    s := 'Plug in a controller';
    w := measureDefault(s);
    printDefault(s, (vgaWidth - w) div 2, 120);

    s := 'Press any key when ready';
    w := measureDefault(s);
    printDefault(s, (vgaWidth - w) div 2, 130);
  end;

  { Debug buttons }
  if GamepadConnected then begin
    { if GamepadButton(BTN_DPAD_UP) then printDefault('UP', 105, 100 - 10); }
    StateLabel('UP', 95, 100 - 10, GamepadButton(BTN_DPAD_UP));
    StateLabel('DOWN', 95, 100 + 10, GamepadButton(BTN_DPAD_DOWN));
    StateLabel('LEFT', 95 - 15, 100, GamepadButton(BTN_DPAD_LEFT));
    StateLabel('RIGHT', 95 + 15, 100, GamepadButton(BTN_DPAD_RIGHT));

    StateLabel('X', 200 - 10, 100, GamepadButton(BTN_X));
    StateLabel('Y', 200, 100 - 10, GamepadButton(BTN_Y));
    StateLabel('A', 200, 100 + 10, GamepadButton(BTN_A));
    StateLabel('B', 200 + 10, 100, GamepadButton(BTN_B));

    StateLabel('LB', 145, 50, GamepadButton(BTN_LB));
    StateLabel('RB', 175, 50, GamepadButton(BTN_RB));
    StateLabel('LT', 145, 60, GamepadButton(BTN_LT));
    StateLabel('RT', 175, 60, GamepadButton(BTN_RT));

    StateLabel('START', 165, 80, GamepadButton(BTN_START));
    StateLabel('BACK', 135, 80, GamepadButton(BTN_BACK));
  end;

  { Debug analogue sticks }
  if GamepadConnected then begin
    if GamepadButton(BTN_LSTICK) then
      circfill(130, 150, 20, green)
    else
      circ(130, 150, 20, white);

    if GamepadButton(BTN_RSTICK) then
      circfill(190, 150, 20, green)
    else
      circ(190, 150, 20, white);

    leftX := GamepadAxis(AXIS_LEFT_X);
    leftY := GamepadAxis(AXIS_LEFT_Y);
    rightX := GamepadAxis(AXIS_RIGHT_X);
    rightY := GamepadAxis(AXIS_RIGHT_Y);

    circfill(130 + round(20 * leftX), 150 + round(20 * leftY), 5, white);
    circfill(190 + round(20 * rightX), 150 + round(20 * rightY), 5, white);

    StateLabel('LSTICK', 120, 180, GamepadButton(BTN_LSTICK));
    StateLabel('RSTICK', 170, 180, GamepadButton(BTN_RSTICK));

    printDefault('LX: ' + f32str(leftX), 40, 150);
    printDefault('LY: ' + f32str(leftY), 40, 160);
    printDefault('RX: ' + f32str(rightX), 220, 150);
    printDefault('RY: ' + f32str(rightY), 220, 160);
  end;

  DrawMouse;
  DrawFPS;
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

