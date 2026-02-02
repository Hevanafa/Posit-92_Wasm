library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  BMFont, Loading, Fullscreen, Graphics,
  Conv, FPS, Logger,
  Keyboard, Mouse,
  ImgRef, ImgRefFast, ImmedGUI, SprEffects,
  Shapes, Timing, WasmMemMgr, VGA,
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
  LightOrange = $FFFFBE00;
  Red = $FFFF5555;
  Black = $FF000000;

var
  lastEsc: boolean;

  { Game state variables }
  actualGameState: TGameStates;
  gameTime: double;
  actualDemoState: TDemoStates;

  gamePerlin: TPerlin;
  noiseCache: longint;
  blackFont: TBMFont;


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

  blackFont := defaultFont;
  blackFont.imgHandle := copyImage(defaultFont.imgHandle);
  replaceColour(blackFont.imgHandle, white, black);

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

function DemoButton(
  const caption: string;
  const x, y, width, height: integer;
  const colour, hoveredColour, pressedColour: longword): boolean;
var
  zone: TZone;
  thisWidgetID: integer;
  buttonColour: longword;
begin
  assertFontSet;

  zone.x := x;
  zone.y := y;
  zone.width := width;
  zone.height := height;

  { Update logic }
  thisWidgetID := getNextWidgetID;
  incNextWidgetID;

  if pointInZone(getMousePoint, zone) then begin
    setHotWidget(thisWidgetID);

    if getMouseJustPressed then setActiveWidget(thisWidgetID);
  end;

  { Render logic }
  if getActiveWidget = thisWidgetID then
    buttonColour := pressedColour
  else if getHotWidget = thisWidgetID then
    buttonColour := hoveredColour
  else 
    buttonColour := colour;

  rectfill(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), buttonColour);
  rect(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), white);

  if (getActiveWidget <> thisWidgetID) and (getHotWidget <> thisWidgetID) then
    printBMFont(blackFont, defaultFontGlyphs, caption, trunc(zone.x + 4), trunc(zone.y + 4))
  else
    TextLabel(caption, trunc(zone.x + 4), trunc(zone.y + 4));

  if getMouseJustReleased and (getHotWidget = thisWidgetID) and (getActiveWidget = thisWidgetID) then
    { activeWidget = -1 }  { Index reset is handled at the end of draw }
    DemoButton := true
  else
    DemoButton := false;
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
  buttonColour: longword;
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

  if actualDemoState = DemoState2D then
    buttonColour := orange
  else buttonColour := white;

  if DemoButton('2D',
    10, vgaHeight - 30, 20, 16,
    buttonColour, lightOrange, red) then
    actualDemoState := DemoState2D;

  if actualDemoState = DemoState1D then
    buttonColour := orange
  else buttonColour := white;

  if DemoButton('1D waveform',
    40, vgaHeight - 30, 70, 16,
    buttonColour, LightOrange, red) then
    actualDemoState := DemoState1D;


  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], (vgaWidth - getImageWidth(imgDosuEXE[1])) div 2, (vgaHeight - getImageHeight(imgDosuEXE[0])) div 2)
  else
    spr(imgDosuEXE[0], (vgaWidth - getImageWidth(imgDosuEXE[0])) div 2, (vgaHeight - getImageHeight(imgDosuEXE[0])) div 2);

  s := 'Perlin noise in Posit-92!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 100);

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
