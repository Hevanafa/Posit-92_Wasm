library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  Loading, Fullscreen,
  Conv, FPS, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast,
  ImmedGUI, Timing, WasmMemMgr, VGA,
  Assets, Perlin;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );

  TDemoStates = (
    DemoState2D = 1,
    DemoState1D = 2
  );

const
  SC_ESC = $01;
  SC_SPACE = $39;
  SC_ENTER = $1C;

  CornflowerBlue = $FF6495ED;
  TurboPascalBlue = $FF0000AA;
  White = $FFFFFFFF;
  Cyan = $FF55FFFF;
  Orange = $FFFF8200;

var
  lastEsc: boolean;

  { Game state variables }
  actualGameState: TGameStates;
  gameTime: double;
  actualDemoState: TDemoStates;

  gamePerlin: TPerlin;
  noiseCache: longint;


{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure hideCursor; external 'env' name 'hideCursor';
procedure hideLoadingOverlay; external 'env' name 'hideLoadingOverlay';
procedure loadAssets; external 'env' name 'loadAssets';

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 160, 0);
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
const
  scale: double = 0.05;  { Smaller = more zoomed out }
var
  a, b: smallint;

  imgNoiseCache: PImageRef;
  noiseValue: double;
  grey: byte;
begin
  hideCursor;
  fitCanvas;

  initImmediateGUI;
  guiSetFont(defaultFont, defaultFontGlyphs);

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;

  actualDemoState := DemoState1D;

  initPerlin(gamePerlin, trunc(getTimer));
  noiseCache := newImage(vgaWidth div 2, vgaHeight div 2);
  imgNoiseCache := getImagePtr(noiseCache);

  for b:=0 to vgaHeight div 2 - 1 do
  for a:=0 to vgaWidth div 2 - 1 do begin
    noiseValue := noise2D(gamePerlin, a * scale, b * scale);

    grey := round(noiseValue * 255);

    unsafeSprPset(imgNoiseCache,
      a, b,
      $FF000000
      or (grey shl 16)
      or (grey shl 8)
      or grey);
  end;
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
begin
  updateDeltaTime;
  incrementFPS;

  { Handle inputs }
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

  { Handle game state updates }
  gameTime := gameTime + dt;

  resetWidgetIndices
end;

procedure draw;
var
  w: integer;
  s: string;
  noiseValue: double;
  a, b: smallint;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen; exit
  end;

  cls(TurboPascalBlue);

  if actualDemoState = DemoState2D then
    { spr(noiseCache, 0, 0); }
    sprStretch(noiseCache, 0, 0, vgaWidth, vgaHeight);

  if actualDemoState = DemoState1D then begin
    for a:=0 to vgaWidth-1 do begin
      { Using `scale = 0.05` }
      noiseValue := noise1D(gamePerlin, (a + gameTime * 10) * 0.05);
      b := round(noiseValue * 40) - 20 + vgaHeight div 2;

      pset(a, b, cyan);
    end;
  end;

  Button('2D', 10, vgaHeight - 30, 20, 20);
  Button('1D waveform', 50, vgaHeight - 30, 60, 20);


  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], (vgaWidth - getImageWidth(imgDosuEXE[1])) div 2, (vgaHeight - getImageHeight(imgDosuEXE[0])) div 2)
  else
    spr(imgDosuEXE[0], (vgaWidth - getImageWidth(imgDosuEXE[0])) div 2, (vgaHeight - getImageHeight(imgDosuEXE[0])) div 2);

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  drawMouse;
  drawFPS;

  resetActiveWidget;

  vgaFlush
end;

exports
  beginLoadingState,
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.
