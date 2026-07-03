library Game;

{$Mode ObjFPC}
{$H+}  { Use AnsiStrings }
{$J-}  { Switch off assignments to typed constants }

uses
  P92Core, P92Fonts, WasmHost,
  P92AssetRegistry,
  Logger, Loading, Fullscreen,
  Keyboard, Mouse,
  SoftwareTex, SoftwareTexDraw, Timing, VGA,
  Assets;

type
  TP92GameStates = (
    GameStateLoading,
    GameStatePlaying
  );

var
  { Game state variables }
  p92GameState: TP92GameStates;
  gameTime: double;

procedure DrawMouse;
begin
  Spr(imgCursor, mouseX, mouseY)
end;

procedure LoadGameAssets;
begin
  p92GameState := GameStateLoading;

  writelog('LoadGameAssets call');
  imgCursor := RequestImage('assets/images/cursor.png');

  imgDosuExe[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuExe[1] := RequestImage('assets/images/dosu_2.png');

  { TODO: RequestBMFont(''); }
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
  if p92GameState = GameStateLoading then begin
    RenderLoadingScreen;
    exit
  end;

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
