library Game;

{$Mode TP}

uses
  Conv, Keyboard, Mouse,
  ImgRef, ImgRefFast,
  PostProc, Timing, WasmMemMgr, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  SC_LEFT = $4B;
  SC_RIGHT = $4D;

type
  TintModes = (
    TintModeNone,
    TintModeNight,
    TintModeSepia,
    TintModeDamage,
    TintModeCount
  );

var
  lastEsc: boolean;
  lastLeft, lastRight: boolean;

  { Init your game state here }
  gameTime: double;
  actualTintMode: integer;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure applyTint(const which: TintModes);
begin
  case which of
    TintModeNight: applyFullTint($FF4060A0);
    TintModeSepia: applyFullTint($FFC0A080);
    TintModeDamage: applyFullTint($FFFF6060);
    else
  end;
end;

function getTintName(const which: TintModes): string;
var
  result: string;
begin
  case which of
  TintModeNone: result := 'None';
  TintModeNight: result := 'Night';
  TintModeSepia: result := 'Sepia';
  TintModeDamage: result := 'Damage';
  else
    result := 'Unknown TintMode: ' + i32str(ord(which));
  end;

  getTintName := result
end;


procedure init;
begin
  initMemMgr;
  initBuffer;
  initDeltaTime;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;

  actualTintMode := 0;
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

  if lastLeft <> isKeyDown(SC_LEFT) then begin
    lastLeft := isKeyDown(SC_LEFT);
    if lastLeft then dec(actualTintMode);
  end;

  if lastRight <> isKeyDown(SC_RIGHT) then begin
    lastRight := isKeyDown(SC_RIGHT);
    if lastRight then inc(actualTintMode);
  end;

  if actualTintMode < 0 then
    actualTintMode := ord(TintModeCount) - 1;

  if actualTintMode >= ord(TintModeCount) then
    actualTintMode := 0;

  gameTime := gameTime + dt
end;

procedure draw;
var
  s: string;
  w: word;
begin
  cls($FF6495ED);

  spr(imgArkRoad, 0, 0);
  applyTint(TintModes(actualTintMode));

  printDefault('Tint mode: ' + getTintName(TintModes(actualTintMode)), 10, 10);
  printDefault('Left / right: Change tint mode', 10, vgaHeight - 20);

  s := 'Art by Kevin Hong';
  w := measureDefault(s);
  printDefault(s, vgaWidth - w - 10, vgaHeight - 20);

  drawMouse;
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

