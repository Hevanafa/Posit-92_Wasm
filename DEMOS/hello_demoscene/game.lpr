library Game;

{$Mode ObjFPC}
{$H+}  { Use AnsiStrings }
{$J-}  { Switch off assignments to typed constants }

uses
  Loading, Fullscreen, Keyboard, Mouse,
  ImgRefFast, Timing, WasmMemMgr, VGA,
  Assets;

var
  { Game state variables }
  gameTime: double;

{ Use this to set `done` to true }
procedure SignalDone; external 'env' name 'SignalDone';
procedure HideCursor; external 'env' name 'HideCursor';
procedure LoadAssets; external 'env' name 'LoadAssets';

procedure DrawMouse;
begin
  Spr(imgCursor, mouseX, mouseY)
end;

procedure Init;
begin
  InitHeapMgr;
  InitDeltaTime;

  LoadAssets;
end;

procedure AfterInit;
begin
  HideCursor;
  FitCanvas;

  { Initialise game state here }
  gameTime := 0.0;
end;

procedure Update;
begin
  UpdateDeltaTime;

  UpdateMouse;
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  gameTime := gameTime + dt
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
  Init, AfterInit, Update, Draw;

begin
{ Starting point is intentionally left empty }
end.
