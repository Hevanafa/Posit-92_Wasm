unit P92Core;

{$Mode ObjFPC}
{$H-}
{$J+}

interface

type
  TEngineRunStates = (
    ersBoot = 1,
    ersLoading = 2,
    ersReady = 3
  );

var
  engineRunState: TEngineRunStates;

procedure InitEngine; public name 'InitEngine';
procedure InitLoadingState; public name 'InitLoadingState';
procedure SetCGAFontHandle(value: longint); public name 'SetCGAFontHandle';

function IsEngineReady: boolean; public name 'IsEngineReady';

procedure EngineUpdate; public name 'EngineUpdate';
procedure EngineDraw; public name 'EngineDraw';
procedure DrawFPS; public name 'DrawFPS';

procedure Print(const txt: string; const x, y: smallint);


implementation

uses
  Conv, WasmMemMgr, FPS, Loading, Logger,
  InteropBuf, Timing, VGA, WasmHost,
  Mouse,
  P92AssetRegistry, SoftwareTexDraw
{$ifdef UseWebGL}
  , WebGL
{$endif}
  ;

var
  cgaFontHandle: longint;

procedure InitEngine;
begin
  engineRunState := ersBoot;
  writelog('ersBoot');

  InitHeapMgr;
  InitInteropBuffer;

  InitDeltaTime;
  InitAssetRegistry;
  InitFPSCounter;

{$ifdef UseWebGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}
end;

procedure InitLoadingState;
begin
  engineRunState := ersLoading;
  FitCanvas;
  writelog('ersLoading');
end;

procedure SetCGAFontHandle(value: longint);
begin
  writelog('SetCGAFontHandle ' + i32str(value));
  cgaFontHandle := value
end;

function IsEngineReady: boolean;
begin
  IsEngineReady := engineRunState = ersReady
end;

procedure EngineUpdate;
begin
  if engineRunState = ersLoading then
    if AllAssetsReady then begin
      engineRunState := ersReady;
      writelog('ersReady');
    end;

  if engineRunState = ersReady then begin
    UpdateDeltaTime;
    IncrementFPS;
    UpdateMouse;
  end;
end;

procedure EngineDraw;
begin
  cls($FF000000);

  if engineRunState = ersLoading then
    RenderLoadingScreen;
end;

procedure DrawFPS;
begin
  print('FPS: ' + i32str(GetLastFPS), VgaWidth - 50, 0)
end;

procedure Print(const txt: string; const x, y: smallint);
var
  c: char;
  left: smallint;
  row, col: smallint;
begin
  left := x;

  for c in txt do begin
    row := ord(c) div 16;
    col := ord(c) mod 16;

    SprRegion(cgaFontHandle, col * 8, row * 8, 8, 8, left, y);
    inc(left, 8)
  end;
end;

end.

