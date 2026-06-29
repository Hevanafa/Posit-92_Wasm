library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  Conv, FPS, Graphics,
  ImgRef, ImgRefFast,
  Keyboard, Mouse,
  Loading, Logger, Panic, Sounds,
  Timing, WasmMemMgr, VGA,
  Assets;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );

const
  SC_ESC = $01;
  SC_SPACE = $39;

  SC_1 = $02;
  SC_2 = $03;
  SC_3 = $04;
  SC_4 = $05;
  SC_5 = $06;

var
  lastEsc, lastSpacebar: boolean;
  lastD1, lastD2, lastD3, lastD4, lastD5: boolean;

  { Init your game state here }
  actualGameState: TGameStates;
  gameTime: double;

{ Use this to set `done` to true }
procedure SignalDone; external 'env' name 'SignalDone';
procedure HideCursor; external 'env' name 'HideCursor';
procedure HideLoadingOverlay; external 'env' name 'HideLoadingOverlay';
procedure LoadAssets; external 'env' name 'LoadAssets';

procedure DrawFPS;
begin
  PrintDefault('FPS:' + I32Str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  Spr(imgCursor, mouseX, mouseY)
end;

procedure BeginLoadingState;
begin
  actualGameState := GameStateLoading;
  LoadAssets
end;

procedure BeginPlayingState;
begin
  { Initialise game state here }
  HideCursor;
  actualGameState := GameStatePlaying;
  gameTime := 0.0;
end;


procedure PlayRandomSFX;
begin
  playSound(1 + random(SfxSlip))
end;


procedure Init;
begin
  InitHeapMgr;
  InitDeltaTime;
  InitFPSCounter
end;

procedure AfterInit;
begin
  BeginPlayingState
end;

procedure Update;
begin
  UpdateDeltaTime;
  IncrementFPS;

  UpdateMouse;

  { Your Update logic here }
  if lastEsc <> IsKeyDown(SC_ESC) then begin
    lastEsc := IsKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      SignalDone
    end;
  end;

  if lastSpacebar <> IsKeyDown(SC_SPACE) then begin
    lastSpacebar := IsKeyDown(SC_SPACE);

    if lastSpacebar then PlayRandomSFX;
  end;

  if lastD1 <> IsKeyDown(SC_1) then begin
    lastD1 := IsKeyDown(SC_1);
    if lastD1 then playSound(1);
  end;

  if lastD2 <> IsKeyDown(SC_2) then begin
    lastD2 := IsKeyDown(SC_2);
    if lastD2 then playSound(2);
  end;

  if lastD3 <> IsKeyDown(SC_3) then begin
    lastD3 := IsKeyDown(SC_3);
    if lastD3 then playSound(3);
  end;

  if lastD4 <> IsKeyDown(SC_4) then begin
    lastD4 := IsKeyDown(SC_4);
    if lastD4 then playSound(4);
  end;

  if lastD5 <> IsKeyDown(SC_5) then begin
    lastD5 := IsKeyDown(SC_5);
    if lastD5 then playSound(5);
  end;

  gameTime := gameTime + dt
end;

procedure Draw;
var
  w: integer;
  s: string;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;

  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := '1, 2, 3, 4, 5 - Play sound';
  w := MeasureDefault(s);
  PrintDefault(s, (vgaWidth - w) div 2, 120);

  s := 'Spacebar - Play a random sound';
  w := MeasureDefault(s);
  PrintDefault(s, (vgaWidth - w) div 2, 130);

  DrawMouse;
  DrawFPS;

  VgaUpload;
  VgaPresent
end;

exports
  { Main game procedures }
  BeginLoadingState,
  Init,
  AfterInit,
  Update,
  Draw;

begin
{ Starting point is intentionally left empty }
end.

