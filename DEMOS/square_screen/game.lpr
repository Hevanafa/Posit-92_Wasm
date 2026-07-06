{
  Square Screen demo
  Part of Posit-92 game engine
  Mixins: bmfont
}

library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92AssetRegistry, P92Fonts, P92WasmHost,
  P92Loading,
  P92Keyboard, P92Mouse,
  P92Tex, P92TexDraw,
  P92Timing, P92VGA,
  Assets;

var
  lastEsc: boolean;

  { Game state variables }
  gameTime: double;

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');

  imgDosuExe[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuExe[1] := RequestImage('assets/images/dosu_2.png');
end;

procedure OnReady;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  gameTime := 0.0;
end;

procedure Update;
begin
  if lastEsc <> IsKeyDown(SC_ESCAPE) then begin
    lastEsc := IsKeyDown(SC_ESCAPE);
    if lastEsc then SignalDone;
  end;

  gameTime := gameTime + DeltaTime
end;

procedure Draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 52, 52)
  else
    spr(imgDosuEXE[0], 52, 52);

  s := 'Hello world!';
  w := MeasureDefault(s);
  PrintDefault(s, (vgaWidth - w) div 2, 88);

  DrawMouse;

  VgaUpload;
  VgaPresent
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

