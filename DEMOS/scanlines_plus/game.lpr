{
  Default boilerplate
  Mixins: bmfont, sound
}

library Game;

{$Mode ObjFPC}
{$H+}  { Use AnsiStrings }
{$J-}  { Switch off assignments to typed constants }

uses
  P92Core, P92Fonts, P92AssetRegistry, P92WasmHost,
  P92Logger, P92BMFont, P92Iif,
  P92Keyboard, P92Mouse,
  P92Graphics, P92Tex, P92TexDraw, P92TexEffects, P92Colour,
  P92Timing, P92FPS, P92VGA,
  Assets;

var
  { Game state variables }
  gameTime: double;

procedure DrawMouse;
begin
  Spr(imgCursor, mouseX, mouseY)
end;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');

  imgSpecimenP92[0] := RequestImage('assets/images/specimen_p-92_1.png');
  imgSpecimenP92[1] := RequestImage('assets/images/specimen_p-92_2.png');
end;

procedure OnReady;
begin
  HideCursor;

  { Initialise game state here }
  gameTime := 0.0
end;

procedure Update;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  gameTime := gameTime + DeltaTime
end;

procedure Draw;
var
  a: word;
  c: char;
  s: string;
  hue, v: double;
  left: smallint;
  frameIdx: smallint;
  colour: longword;
  x, y: smallint;
  w, h: smallint;
  scale: double;
begin
  { Cls($FF6495ED); }

  for a:=0 to VgaHeight - 1 do begin
    v := 64 / 255 + sin((a / 50 - frac(GetTimer)) * 2 * PI) * (32 / 255);
    colour := HSVtoRGB(137 / 255, 1.0, v);
    hline(0, VgaWidth - 1, a, colour);
  end;

  scale := 1.0 + abs(sin(frac(GetTimer) * 2 * PI)) * 0.25;

  { SprOutline(imgSpecimenP92[1], 148, 84, $FFFFFFFF) }
  x := 160;
  y := 100;

  w := trunc(GetTextureWidth(imgSpecimenP92[1]) * scale);
  h := trunc(GetTextureHeight(imgSpecimenP92[1]) * scale);

  frameIdx := U16Iif((trunc(gameTime * 4) and 1) > 0, 1, 0);

  SprStretch(
    imgSpecimenP92[frameIdx],
    x - w div 2, y - h div 2,
    w, h);

  s := 'Now with more scanlines!';
  w := MeasureDefault(s);
  left := (VgaWidth - w) div 2;

  { PrintDefault('Hello world!', left, 120); }
  { PrintCharColour('Z', 10, 10, $FFFFFFFF); }

  for a:=1 to length(s) do begin
    c := s[a];

    hue := (a-1) / length(s) + frac(GetTimer);
    if hue > 1.0 then hue := hue - 1.0;

    colour := HSVtoRGB(hue, 1.0, 1.0);
    inc(left, PrintCharColour(c, left, 128, colour));
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
