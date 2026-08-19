{
  BMFont test project
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

var
  { Game state variables }
  gameTime: double;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');

  imgSpecimenP92[0] := RequestImage('assets/images/specimen_p-92_1.png');
  imgSpecimenP92[1] := RequestImage('assets/images/specimen_p-92_2.png');
end;

procedure OnReady;
begin

end;


procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure DrawOnce;
const
  OpCount = 5000;
var
  a: word;
  startTick, endTick: double;
  s: string;
  w: word;
begin
  Cls($FF6495ED);

  startTick := GetTimer;

  {
    Original 1000 ops: 0.0320s

    Original 5000 ops: 0.1680s
    After eliminating per pixel clipping: 0.0590s
    After using rowBase: 0.0530s
    After inlining SprPGet: 0.0430s
    After using pointer arithmetics: 0.0330s, 0.0280s
  }
  for a:=1 to OpCount do
    PrintDefault('Hello world!', random(VgaWidth) - 30, random(VgaHeight + 10) - 20);

  endTick := GetTimer;

  s := i32str(OpCount) + ' operations done in ' + f32str(endTick - startTick) + 's';
  w := MeasureDefault(s);
  RectFill(10, VgaHeight - 20, 10 + w, VgaHeight - 20 + BorrowBMFontPtr(GetDefaultFontHandle)^.lineHeight, $FF000000);
  PrintDefault(s, 10, VgaHeight - 20);
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

  PrintDefaultCentred('Hello world!', VgaWidth div 2, 120);

  PrintDefault('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 10, 10);
  PrintDefault('abcdefghijklmnopqrstuvwxyz', 10, 30);
  PrintDefault('0123456789', 10, 50);
  PrintDefault('!"#$%&''()*+,-./ :;<=>?@ [\]^_ ` {|}~', 10, 70);

  DrawMouse;
  DrawFPS;
end;

exports
  OnPreload,
  OnReady,
  Update, Draw;
  { DrawOnce; }

begin
{ Starting point is intentionally left empty }
end.
