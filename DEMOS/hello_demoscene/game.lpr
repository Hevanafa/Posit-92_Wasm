library Game;

{$Mode ObjFPC}
{$H+}  { Use AnsiStrings }
{$J-}  { Switch off assignments to typed constants }

uses
  EngineCore, EngineFonts, WasmHost,
  Logger, Loading, Fullscreen,
  Keyboard, Mouse,
  ImgRefFast, Timing, VGA,
  Assets;

var
  { Game state variables }
  gameTime: double;

procedure DrawMouse;
begin
  Spr(imgCursor, mouseX, mouseY)
end;

procedure LoadGameAssets;
begin
  writelog('LoadGameAssets call');
  imgDosuExe[0] := RequestImage('assets/images/dosu_0.png');
  imgDosuExe[1] := RequestImage('assets/images/dosu_1.png');
end;

{ Called after LoadGameAssets is finished }
procedure OnReady;
begin
  HideCursor;
  FitCanvas;

  { Initialise game state here }
  gameTime := 0.0
end;

procedure Update;
begin
  UpdateDeltaTime;
  UpdateMouse;

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

  VgaUpload;
  VgaPresent
end;

exports
  LoadGameAssets, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.
