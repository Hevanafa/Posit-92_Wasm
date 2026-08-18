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
  P92Keyboard, P92Mouse, P92Sounds,
  P92TexDraw, P92Timing, P92FPS, P92VGA,
  Assets;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');

  imgSpecimenP92[0] := RequestImage('assets/images/specimen_p-92_1.png');
  imgSpecimenP92[1] := RequestImage('assets/images/specimen_p-92_2.png');
end;

procedure OnReady;
begin

end;

procedure DrawOnce;
begin
  writelog('DrawOnce call');

  Cls($FF6495ED);

  Spr(imgSpecimenP92[0], 148, 84);

  PrintDefaultCentred('Hello world!', VgaWidth div 2, 120);
end;

exports
  OnPreload,
  OnReady,
  DrawOnce;

begin
{ Starting point is intentionally left empty }
end.
