library Game;

{$Mode ObjFPC}
{$H+}
{$J-}

uses
  P92Core, P92AssetRegistry, P92WasmHost,
  P92Conversions, P92FPS, P92Logger, P92BMFont,
  P92Keyboard, P92Mouse,
  P92Tex, P92TexDraw,
  P92RichText, P92Timing, P92VGA,
  Assets;

const
  CornflowerBlue = $FF6495ED;

  Palette: array of longword = (
    $FF000000,
    $FFFF5555,
    $FF55FF55,
    $FF5555FF
  );

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;


procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(fontDefault, text, x, y)
end;

function MeasureDefault(const text: string): word;
begin
  MeasureDefault := measureBMFont(fontDefault, text)
end;

procedure PrintDefaultCentred(const text: string; const cx, y: integer);
var
  w: word;
begin
  w := MeasureDefault(text);
  PrintDefault(text, cx - w div 2, y)
end;

procedure DrawFPS;
begin
  PrintDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  spr(texCursor, GetMouseX, GetMouseY)
end;

procedure OnPreload;
begin
  texCursor := RequestImage('assets/images/cursor.png');

  texDosuExe[0] := RequestImage('assets/images/dosu_1.png');
  texDosuExe[1] := RequestImage('assets/images/dosu_2.png');
end;

procedure OnReady;
begin
  HideCursor;

  { Initialise game state here }
  gameTime := 0.0;

  rtfSetFont(fontDefault);

  rtfSetBoldFont(fontBold);
  rtfSetItalicFont(fontItalic);
  rtfSetBoldItalicFont(fontBoldItalic);
end;


procedure Update;
begin
  if lastEsc <> IsKeyDown(SC_ESCAPE) then begin
    lastEsc := IsKeyDown(SC_ESCAPE);

    if lastEsc then SignalDone;
  end;

  { Handle game state updates }
  gameTime := gameTime + DeltaTime;
end;

procedure Draw;
begin
  cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(texDosuExe[1], 148, 88)
  else
    spr(texDosuExe[0], 148, 88);

  RichTextLabel('\bBold text,\plain Regular text', 20, 120, Palette);
  RichTextLabel('Black text\cf1 Red text \cf0Black text', 20, 140, Palette);
  RichTextLabel('\bBold,\b0\i Italic,\i0\b\i Bold italic', 20, 150, Palette);
  RichTextLabel('\cf1Colour 1 \cf2Colour 2 \cf3 Colour 3', 20, 160, Palette);

  DrawMouse;
  DrawFPS;
end;

exports
  OnPreload,
  OnReady,
  Update,
  Draw;

begin
{ Starting point is intentionally left empty }
end.

