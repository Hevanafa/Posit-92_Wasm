unit P92Core;

{$Mode ObjFPC}
{$H-}
{$J+}

interface

type
  TEngineRunStates = (
    ersBoot = 1,
    ersPreload = 2,
    ersReady = 3
  );

var
  engineRunState: TEngineRunStates;

procedure InitEngine; public name 'InitEngine';
procedure InitLoadingState; public name 'InitLoadingState';
procedure SetCGAFontHandle(value: longint); public name 'SetCGAFontHandle';

function IsEngineReady: boolean; public name 'IsEngineReady';

procedure P92Update; public name 'P92Update';
procedure P92Draw; public name 'P92Draw';

procedure Print(const txt: string; const x, y: smallint);


implementation

uses
  P92Conversions, P92WasmMemMgr,
  P92FPS, P92Loading, P92Logger,
  P92InteropBuf, P92Timing,
  P92Mouse,
  P92AssetRegistry, P92TexDraw,
  P92VGA, P92WasmHost
{$ifdef UseWebGL}
  , P92WebGL
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
  InitFPSCounter;

  InitAssetRegistry;

{$ifdef UseWebGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}
end;

procedure InitLoadingState;
begin
  engineRunState := ersPreload;
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

procedure P92Boot;
begin
  cgaFontHandle := RequestImage('assets/CGA8x8.png');
end;

procedure P92Update;
begin
  if engineRunState = ersBoot then
    if AllAssetsReady then begin
      engineRunState := ersPreload;
      writelog('ersPreload');
    end;

  if engineRunState = ersPreload then
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

procedure P92Draw;
begin
  cls($FF000000);

  if engineRunState = ersPreload then
    RenderLoadingScreen;
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

