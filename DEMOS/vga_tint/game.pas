library Game;

{$Mode TP}

uses
  Conv, Keyboard, Mouse,
  ImgRef, ImgRefFast,
  Timing, VGA,
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

procedure applyFullTint(const which: TintModes);
var
  px, py: word;
  colour: longword;
  r, g, b: byte;
begin
  case which of
    TintModeNight: begin
      for py:=0 to vgaHeight - 1 do
      for px:=0 to vgaWidth - 1 do begin
        colour := unsafePget(px, py);
        
        r := colour shr 16 and $FF;
        g := colour shr 8 and $FF;
        b := colour and $FF;

        { $4060A0 };
        r := (r * $40) div 255;
        g := (g * $60) div 255;
        b := (b * $A0) div 255;

        colour := (colour and $FF000000) or (r shl 16) or (g shl 8) or b;
        unsafePset(px, py, colour)
      end;
    end;
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
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  spr(imgArkRoad, 0, 0);

  {
  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);
  }

  applyFullTint(TintModes(actualTintMode));

  printDefault('Tint mode: ' + getTintName(TintModes(actualTintMode)), 10, 10);
  printDefault('Left / right: Change tint mode', 10, vgaHeight - 20);

  drawMouse;
  flush
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

