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
  P92Logger, P92BMFont,
  P92Keyboard, P92Mouse,
  P92Graphics, P92TexDraw, P92TexEffects, P92Colour,
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
  w: word;
  c: char;
  s: string;
  hue, v: double;
  left: smallint;
  colour: longword;
begin
  { Cls($FF6495ED); }

  for a:=0 to VgaHeight - 1 do begin
    v := 64 / 255 + sin((a / 50 - frac(GetTimer)) * 2 * PI) * (32 / 255);
    colour := HSVtoRGB(137 / 255, 1.0, v);
    hline(0, VgaWidth - 1, a, colour);
  end;

  if (trunc(gameTime * 4) and 1) > 0 then
    SprOutline(imgSpecimenP92[1], 148, 84, $FFFFFFFF)
  else
    SprOutline(imgSpecimenP92[0], 148, 84, $FFFFFFFF);

  s := 'Hello world!';
  w := MeasureDefault(s);
  left := (VgaWidth - w) div 2;

  { PrintDefault('Hello world!', left, 120); }
  { PrintCharColour('Z', 10, 10, $FFFFFFFF); }

  for a:=1 to length(s) do begin
    c := s[a];

    hue := (a-1) / length(s) + frac(GetTimer);
    if hue > 1.0 then hue := hue - 1.0;

    colour := HSVtoRGB(hue, 1.0, 1.0);
    inc(left, PrintCharColour(c, left, 120, colour));
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
