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
  P92Logger,
  P92Keyboard, P92Mouse,
  P92Graphics, P92TexDraw, P92Colour,
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
  colour: longword;
begin
  { Cls($FF6495ED); }

  for a:=0 to VgaHeight - 1 do begin
    colour := HSVtoRGB(137 / 255, 1.0, 38 / 255);
    hline(0, VgaWidth - 1, a, colour);
  end;

  if (trunc(gameTime * 4) and 1) > 0 then
    Spr(imgSpecimenP92[1], 148, 84)
  else
    Spr(imgSpecimenP92[0], 148, 84);

  PrintDefaultCentred('Hello world!', VgaWidth div 2, 120);

  DrawMouse;
  DrawFPS;
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.
