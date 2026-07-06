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

function GetBootOptionBoolean(key: string): boolean;
function JsGetBootOptionBoolean: boolean; external 'env' name 'JsGetBootOptionBoolean';

procedure InitEngine; public name 'InitEngine';
procedure SetCGAFontHandle(value: longint); public name 'SetCGAFontHandle';

function IsEngineReady: boolean; public name 'IsEngineReady';
procedure HostCallOnPreload; external 'env' name 'HostCallOnPreload';
procedure HostCallOnReady; external 'env' name 'HostCallOnReady';

procedure P92Boot; public name 'P92Boot';
procedure P92Update; public name 'P92Update';
procedure P92Draw; public name 'P92Draw';

procedure Print(const txt: string; const x, y: smallint);


implementation

uses
  P92Fonts, P92AssetRegistry, P92WasmHost,
  P92Conversions, P92WasmMemMgr,
  P92FPS, P92Loading, P92Logger,
  P92InteropBuf, P92Timing,
  P92Mouse,
  P92TexDraw, P92VGA
{$ifdef P92_IMMEDIATE_GUI}
  , P92ImmediateGUI
{$endif}
{$ifdef P92_WEBGL}
  , P92WebGL
{$endif}
  ;

var
  cgaFontHandle: longint;

function GetBootOptionBoolean(key: string): boolean;
begin
  WriteInteropString(key);
  GetBootOptionBoolean := JsGetBootOptionBoolean
end;

procedure InitEngine;
begin
  engineRunState := ersBoot;
  writelog('ersBoot');

  InitHeapMgr;
  InitInteropBuffer;
  InitDeltaTime;
  InitFPSCounter;

  InitAssetRegistry;

{$ifdef P92_WEBGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}
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

procedure InitPreloadState;
begin
  engineRunState := ersPreload;
  writelog('ersPreload');
  FitCanvas;

  if GetBootOptionBoolean('defaultFont') then
    LoadDefaultFont;

  HostCallOnPreload
end;

procedure InitReadyState;
begin
  engineRunState := ersReady;
  writelog('ersReady');
  HostCallOnReady
end;

procedure P92Update;
begin
  if engineRunState = ersBoot then begin
    if AllAssetsReady then
      InitPreloadState;
    exit
  end

  else if engineRunState = ersPreload then begin
    if AllAssetsReady then
      InitReadyState;
    exit
  end

  else if engineRunState = ersReady then begin
    UpdateDeltaTime;
    IncrementFPS;

{$ifdef P92_IMMEDIATE_GUI}
    ResetWidgetIndices;

    UpdateGUILastMouseButton;
    UpdateMouse;
    UpdateGUIMousePoint;

{$else}
    UpdateMouse;
{$endif}
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

