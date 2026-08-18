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
  P92Logger, P92Conversions,
  P92Graphics, P92Keyboard, P92Mouse, P92Sounds,
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
  OpCount = 5000;
var
  startTick, endTick: double;
  a: word;
  s: string;
  w: word;
begin
  writelog('DrawOnce call');
  startTick := GetTimer;

  Cls($FF6495ED);

  { Original: 0.0710s,
    After using inline: 0.0630s
    After using RGBA on the hot path: 0.0600s
    After clipping: 0.0270s }
  { for a:=1 to 1000 do
    Spr(imgSpecimenP92[0], random(VgaWidth) - 12, Random(VgaHeight) - 12); }

  { Original 5000 ops: 0.1350s
    After row stride opt: 0.1300s
    After PGet inlining: 0.0920s
    After pointer dereferencing on both SprPGet and PSet: 0.0560s }
  for a:=1 to OpCount do
    Spr(imgSpecimenP92[0], random(VgaWidth) - 12, Random(VgaHeight) - 12);

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
