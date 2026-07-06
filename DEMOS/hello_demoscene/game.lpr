library Game;

{$Mode ObjFPC}
{$H+}  { Use AnsiStrings }
{$J-}  { Switch off assignments to typed constants }

uses
  P92Core, P92Fonts, P92AssetRegistry, P92WasmHost,
  P92Conversions, P92FPS,
  P92Logger, P92Loading,
  P92Keyboard, P92Mouse,
  P92Tex, P92TexDraw, P92PanicDisplay,
  P92Timing, P92VGA,
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

  imgDosuExe[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuExe[1] := RequestImage('assets/images/dosu_2.png');

  { PanicHaltDisplay('This is a test!'); }
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
    Spr(imgDosuEXE[1], 148, 88)
  else
    Spr(imgDosuEXE[0], 148, 88);

  PrintDefaultCentred('Hello world!', VgaWidth div 2, 120);

  DrawMouse;
  DrawFPS;

  VgaUpload;
  VgaPresent
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.
