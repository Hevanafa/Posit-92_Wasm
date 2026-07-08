unit P92Core;

{$Mode ObjFPC}
{$H-}
{$J+}

interface

function GetBootOptionBoolean(key: string): boolean;
function JsGetBootOptionBoolean: boolean; external 'env' name 'JsGetBootOptionBoolean';

procedure InitEngine; public name 'InitEngine';
function GetCgaFontHandle: longint;
procedure SetCGAFontHandle(value: longint);

function IsEngineReady: boolean; public name 'IsEngineReady';
procedure HostCallOnPreload; external 'env' name 'HostCallOnPreload';
procedure HostCallOnReady; external 'env' name 'HostCallOnReady';

procedure P92Boot; public name 'P92Boot';
procedure P92Update; public name 'P92Update';
procedure P92Draw; public name 'P92Draw';
procedure P92AfterDraw; public name 'P92AfterDraw';

procedure PrintChar(const c: char; const x, y: smallint);
procedure Print(const txt: string; const x, y: smallint);
procedure PrintWrap(const txt: string; x, y, wrapWidth: smallint);


implementation

uses
  P92Fonts, P92AssetRegistry, P92WasmHost,
  P92Conversions, P92WasmMemMgr,
  P92FPS, P92Loading, P92Logger,
  P92Sounds, P92InteropBuf, P92Timing,
  P92Keyboard, P92Mouse,
  P92TexDraw, P92VGA
{$ifdef P92_IMMEDIATE_GUI}
  , P92ImmediateGUI
{$endif}
{$ifdef P92_WEBGL}
  , P92WebGL
{$endif}
  ;

type
  TEngineRunStates = (
    ersBoot = 1,
    ersPreload = 2,
    ersReady = 3
  );

const
  DebugEngineRunStates = true;

var
  engineRunState: TEngineRunStates;
  enableDefaultBMFont: boolean;

  { Default boot font }
  cgaFontHandle: longint;

  { Screenshot feature }
  lastF2: boolean;
  enableScreenshotHotkey: boolean;

function GetCgaFontHandle: longint;
begin
  GetCgaFontHandle := cgaFontHandle
end;

function GetBootOptionBoolean(key: string): boolean;
begin
  WriteInteropString(key);
  GetBootOptionBoolean := JsGetBootOptionBoolean
end;

procedure InitEngine;
begin
  engineRunState := ersBoot;
  if DebugEngineRunStates then
    writelog('ersBoot');

  InitHeapMgr;
  InitInteropBuffer;
  InitDeltaTime;
  InitFPSCounter;

  InitAssetRegistry;
  InitSounds;

{$ifdef P92_WEBGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}

  enableDefaultBMFont := GetBootOptionBoolean('defaultFont');
  enableScreenshotHotkey := GetBootOptionBoolean('enableScreenshotHotkey');
end;

procedure SetCGAFontHandle(value: longint);
begin
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

  if DebugEngineRunStates then
    writelog('ersPreload');

  FitCanvas;

  if enableDefaultBMFont then
    LoadDefaultFont;

  HostCallOnPreload
end;

procedure InitReadyState;
begin
  engineRunState := ersReady;

  if DebugEngineRunStates then
    writelog('ersReady');

  FitCanvas;

{$ifdef P92_IMMEDIATE_GUI}
  InitImmediateGUI;
{$endif}

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

    if enableScreenshotHotkey then begin
      if lastF2 <> isKeyDown(SC_F2) then begin
        lastF2 := isKeyDown(SC_F2);

        if lastF2 then JsTakeScreenshot;
      end;
    end;
  end;
end;

procedure P92Draw;
begin
  cls($FF000000);

  if engineRunState = ersPreload then
    RenderLoadingScreen;
end;

procedure P92AfterDraw;
begin
{$ifdef P92_IMMEDIATE_GUI}
  ResetActiveWidget;
{$endif}

{$ifdef P92_WEBGL}
  VgaUpload;
  WebGLPresent;
{$else}
  VgaUpload;
  VgaPresent;
{$endif}
end;

procedure PrintChar(const c: char; const x, y: smallint);
var
  row, col: smallint;
begin
  if not (ord(c) in [1..255]) then exit;

  row := ord(c) div 16;
  col := ord(c) mod 16;

  SprRegion(
    cgaFontHandle,
    col * 8, row * 8,
    8, 8,
    x, y)
end;

procedure Print(const txt: string; const x, y: smallint);
var
  c: char;
  left: smallint;
begin
  left := x;

  for c in txt do begin
    PrintChar(c, left, y);
    inc(left, 8)
  end;
end;

procedure PrintWrap(const txt: string; x, y, wrapWidth: smallint);
var
  c: char;
  left: smallint;
begin
  left := 0;

  for c in txt do begin
    if c = #10 then begin
      left := 0;
      inc(y, 8);
      continue;
    end;
    if c = #13 then continue;

    PrintChar(c, x + left, y);
    inc(left, 8);

    if left >= wrapWidth then begin
      left := 0;
      inc(y, 8);
    end;
  end;

end;

end.

