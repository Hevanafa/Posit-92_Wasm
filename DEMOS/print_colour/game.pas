library Game;

{$Mode ObjFPC}
{$J-}

uses
  BMFont, Colour, Conv, FPS,
  Fullscreen, ImgRef, ImgRefFast,
  Loading, Keyboard, Maths, Mouse,
  Panic, Timing, WasmMemMgr, VGA,
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

  Black = $FF000000;
  DarkBlue = $FF0000AA;
  Red = $FFFF5555;

var
  lastEsc: boolean;

  { Game state variables }
  actualGameState: TGameStates;
  gameTime: double;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure loadAssets; external 'env' name 'loadAssets';

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
  initHeapMgr;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
begin
  beginPlayingState
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then signalDone;
  end;

  gameTime := gameTime + dt
end;

procedure draw;
var
  w: integer;
  s: string;
  colour: longword;
  a, left: word;
  hue, x: double;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;

  cls(DarkBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := 'Hello world!';
  w := measureDefault(s);

  { colour := HSVtoRGB(gameTime - trunc(gameTime), 1.0, 1.0); }
  { printColour(s,
    (vgaWidth - w) div 2, 120,
    colour); }

  { Debug gameTime }
  printDefault('gameTime: ' + f32str(gameTime), 10, vgaHeight - 20);

  x := (vgaWidth - w) / 2;
  left := 0;
  for a:=1 to length(s) do begin
    hue := (a * 0.1) + (gameTime - trunc(gameTime));
    colour := HSVtoRGB(hue - trunc(hue), 1.0, 1.0);

    inc(left,
      printCharColour(s[a],
      trunc(x + left), 120,
      colour));
  end;

  drawMouse;
  vgaFlush
end;

exports
  { Main game procedures }
  beginLoadingState,
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.

