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
  P92Logger, P92Conversions, P92Graphics,
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
const
  OpCount = 1000;
var
  a: word;
  startTick, endTick: double;
  s: string;
  w: word;
begin
  Cls($FF6495ED);

  startTick := GetTimer;

  { Original 1000 ops: 0.0320s }
  for a:=1 to OpCount do
    PrintDefault('Hello world!', random(VgaWidth) - 30, random(VgaHeight + 10) - 20);

  endTick := GetTimer;

  s := i32str(OpCount) + ' operations done in ' + f32str(endTick - startTick) + 's';
  w := MeasureDefault(s);
  RectFill(10, VgaHeight - 20, 10 + w, VgaHeight - 20 + BorrowBMFontPtr(GetDefaultFontHandle)^.lineHeight, $FF000000);
  PrintDefault(s, 10, VgaHeight - 20);
end;

exports
  OnPreload,
  OnReady,
  DrawOnce;

begin
{ Starting point is intentionally left empty }
end.
