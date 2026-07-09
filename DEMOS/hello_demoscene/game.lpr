{
  Default boilerplate
  Mixins: bmfont, sound
}

library Game;

{$Mode ObjFPC}
{$H+}  { Use AnsiStrings }
{$J-}  { Switch off assignments to typed constants }

uses
  P92Core, P92Fonts, P92WasmHost, P92AssetRegistry,
  P92Logger,
  P92Keyboard, P92Mouse,
  P92TexDraw, P92Timing, P92FPS, P92VGA,
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

  imgTest := RequestImage('assets/fonts/nokia_cellphone_fc_8_0.png');
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
begin
  Cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    Spr(imgSpecimenP92[1], 148, 84)
  else
    Spr(imgSpecimenP92[0], 148, 84);

  Spr(imgSpecimenP92[0], 148, 144);
  Spr(imgSpecimenP92[1], 188, 144);

  { spr(bmfonts[1].font.texHandle, 10, 10); }
  { PrintDefaultCentred('Hello world!', VgaWidth div 2, 120); }

  SprRegion(imgTest, 0, 0, 20, 20, 10, 10);

  DrawMouse;
  DrawFPS;
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.
