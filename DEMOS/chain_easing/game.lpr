{
  Chain Easing demo
  Mixins: bmfont
}

library Game;

{$Mode ObjFPC}
{$H+}
{$J-}

uses
  P92Core, P92AssetRegistry,
  P92Conversions, P92FPS, P92Logger,
  P92Keyboard, P92Mouse,
  P92Tex, P92TexDraw, P92TexEffects,
  P92Easings, ImmediateGUI,
  P92Timing,
  P92PostProc, P92VGA,
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
  
  SC_W = $11;
  SC_A = $1E;
  SC_S = $1F;
  SC_D = $20;

  Velocity = 100;

  CornflowerBlue = $FF6495ED;

var
  lastEsc: boolean;

  { Init your game state here }
  actualGameState: TGameStates;
  gameTime: double;

  { Easing chain state variables }
  isChainStarted, isChainComplete: boolean;
  chainIdx: integer;
  
  startX, endX: integer;
  startAngle, endAngle: double;
  chainLerpTimer: TLerpTimer;

  blinkyX, blinkyY: double;


procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');

  imgDosuEXE[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuEXE[1] := RequestImage('assets/images/dosu_2.png');

  imgBlinky := RequestImage('assets/images/cursor.png');
end;

procedure OnReady;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;

  initImmediateGUI;
  guiSetFont(defaultFont, defaultFontGlyphs);

  blinkyX := 160;
  blinkyY := 144;

  replaceColour(defaultFont.imgHandle, $FFFFFFFF, $FF000000)
end;

procedure BeginEasingChain;
begin
  isChainStarted := true;
  isChainComplete := false;
  chainIdx := 0;

  startX := 100;
  endX := 150;
  initLerp(chainLerpTimer, getTimer, 1.0)
end;


procedure Update;
var
  perc: double;
  x: double;
begin
  updateDeltaTime;
  incrementFPS;

  updateGUILastMouseButton;
  updateMouse;
  updateGUIMousePoint;

  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  if not isChainStarted then begin
    if isKeyDown(SC_W) then blinkyY := blinkyY - Velocity * dt;
    if isKeyDown(SC_S) then blinkyY := blinkyY + Velocity * dt;

    if isKeyDown(SC_A) then blinkyX := blinkyX - Velocity * dt;
    if isKeyDown(SC_D) then blinkyX := blinkyX + Velocity * dt;
  end;

  { Handle game state updates }
  gameTime := gameTime + dt;

  if isChainStarted and not isChainComplete then begin
    { Handle state transition }
    if isLerpComplete(chainLerpTimer, getTimer) then begin
      case chainIdx of
      0: begin
        perc := getLerpPerc(chainLerpTimer, getTimer);
        x := lerpEaseOutSine(startX, endX, perc);  { current X }

        startX := trunc(x);
        endX := endX - 50;
        initLerp(chainLerpTimer, getTimer, 1.0);

        inc(chainIdx)
      end;
      1: begin
        perc := getLerpPerc(chainLerpTimer, getTimer);
        x := lerpEaseOutSine(startX, endX, perc);  { current X }
        
        startX := trunc(x);
        endX := endX + 100;
        startAngle := 0.0;
        endAngle := 2 * PI;
        initLerp(chainLerpTimer, getTimer, 2.0);

        inc(chainIdx)
      end;
      2: inc(chainIdx);
      3: begin
        perc := getLerpPerc(chainLerpTimer, getTimer);
        x := lerpEaseOutSine(startX, endX, perc);  { current X }
        blinkyX := x;

        isChainStarted := false;
        isChainComplete := true
      end
      end;
    end;
  end;

  resetWidgetIndices
end;

procedure Draw;
var
  perc: double;
  x, angle: double;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;

  cls(CornflowerBlue);

  if Button('Start Lerp', 50, 50, 80, 20) then
    BeginEasingChain;

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);
 
  if not isChainStarted then
    CentredLabel('WASD to move', vgaWidth div 2, 120)
  else
    CentredLabel('Easing chain is in progress...', vgaWidth div 2, 120);

  if isChainStarted then begin
    case chainIdx of
      2: begin
        { Current state --> apply easing --> handle rendering }
        perc := getLerpPerc(chainLerpTimer, getTimer);

        x := lerpEaseOutSine(startX, endX, perc);
        angle := lerpEaseOutSine(startAngle, endAngle, perc);

        sprRotate(imgBlinky, trunc(x) + 8, trunc(blinkyY) + 8, angle);
      end;
      else begin
        perc := getLerpPerc(chainLerpTimer, getTimer);
        x := lerpEaseOutSine(startX, endX, perc);
        spr(imgBlinky, trunc(x), trunc(blinkyY));
      end
    end;
  end else
    spr(imgBlinky, trunc(blinkyX), trunc(blinkyY));

  CentredLabel('chainIdx ' + i32str(chainIdx), vgaWidth div 2, 180);

  resetActiveWidget;

  DrawMouse;
  drawFPS;

  VgaUpload;
  VgaPresent
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

