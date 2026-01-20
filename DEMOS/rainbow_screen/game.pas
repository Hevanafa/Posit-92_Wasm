library Game;

{$Mode ObjFPC}
{$J-}

uses
  Fullscreen, Loading,
  Keyboard, Mouse, Maths,
  ImgRef, ImgRefFast,
  Timing, WasmMemMgr, VGA,
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
  White = $FFFFFFFF;

var
  lastEsc: boolean;

  { Init your game state here }
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
  gameTime := 0.0
end;

{ h, s, v: [0.0, 1.0] }
function HSVtoRGB(h, s, v: double): longword;
var
  r, g, b: byte;
  i: integer;
  f, p, q, t: double;
begin
  h := clamp(h, 0.0, 1.0);
  s := clamp(s, 0.0, 1.0);
  v := clamp(v, 0.0, 1.0);

  { Greyscale }
  if s = 0.0 then begin
    r := trunc(v * 255);
    g := r;
    b := r;
    HSVtoRGB := $FF000000 or (r shl 16) or (g shl 8) or b;
    exit
  end;

  { Convert hue to [0.0, 6.0] }
  h := h * 6.0;
  i := trunc(h);
  f := h - i;

  p := v * (1.0 - s);
  q := v * (1.0 - s * f);
  t := v * (1.0 - s * (1.0 - f));

  { Determine RGB }
  case i mod 6 of
    0: begin r := trunc(v * 255); g := trunc(t * 255); b := trunc(p * 255); end;
    1: begin r := trunc(q * 255); g := trunc(v * 255); b := trunc(p * 255); end;
    2: begin r := trunc(p * 255); g := trunc(v * 255); b := trunc(t * 255); end;
    3: begin r := trunc(p * 255); g := trunc(q * 255); b := trunc(v * 255); end;
    4: begin r := trunc(t * 255); g := trunc(p * 255); b := trunc(v * 255); end;
    5: begin r := trunc(v * 255); g := trunc(p * 255); b := trunc(q * 255); end;
  end;

  HSVtoRGB := $FF000000 or (r shl 16) or (g shl 8) or b
end;


procedure init;
begin
  initHeapMgr;
  initDeltaTime;
end;

procedure afterInit;
begin
  beginPlayingState
end;

procedure update;
begin
  updateDeltaTime;

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
  hue, v: double;
  a, b: word;
  colour: longword;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;

  { cls($FF6495ED); }

  for b:=0 to vgaHeight - 1 do
  for a:=0 to vgaWidth - 1 do begin
    hue := a / (vgaWidth) + getTimer / 2;
    hue := hue - trunc(hue);
    v := 0.25 + (1.0 - b / (vgaHeight)) * 0.75;
    colour := HSVtoRGB(hue, 1.0, v);
    unsafePset(a, b, colour)
  end;

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

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

