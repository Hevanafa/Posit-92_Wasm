unit P92Core;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }

interface

{$ifdef P92_SDL2}
type
  TCallback = procedure;

  TP92AppConfig = record
    { Window }
    windowTitle: string;
    width: smallint;
    height: smallint;
    sdlScale: smallint;

    { Default font }
    enableDefaultFont: boolean;
    defaultFontPath: string;

    { Features }
    fps: smallint;
    enableScreenshotHotkey: boolean;

    { Callbacks }
    OnPreload: TCallback;
    OnReady: TCallback;
    Update: TCallback;
    Draw: TCallback;
    OnCleanup: TCallback;
  end;

var
  bootConfig: TP92AppConfig;
{$endif}

{$ifdef P92_WASM}
function GetBootOptionBoolean(key: string): boolean;
function JsGetBootOptionBoolean: boolean; external 'env' name 'JsGetBootOptionBoolean';

function GetCgaFontHandle: longint;
procedure SetCGAFontHandle(value: longint);

function IsEngineReady: boolean; public name 'IsEngineReady';
procedure HostCallOnPreload; external 'env' name 'HostCallOnPreload';
procedure HostCallOnReady; external 'env' name 'HostCallOnReady';
{$endif}

procedure P92Boot; public name 'P92Boot';
procedure P92Update; public name 'P92Update';
procedure P92Draw; public name 'P92Draw';
procedure P92AfterDraw; public name 'P92AfterDraw';

procedure PrintChar(const c: char; const x, y: smallint);
procedure Print(const txt: string; const x, y: smallint);
procedure PrintWrap(const txt: string; x, y, wrapWidth: smallint);

{$ifdef P92_SDL2}
function DefaultP92AppConfig: TP92AppConfig;
procedure P92Start(const appConfig: TP92AppConfig);
{$endif}


implementation

uses
{$ifdef P92_SDL2}
  SysUtils, SDL2, SDL2_Image,
  P92AssetRegistry, P92CoreSDL2,
  P92Fonts, P92Conversions, P92Logger,
  P92Keyboard, P92Mouse,
  P92TexDraw, P92TexRef,
  P92Strings, P92Timing, P92FPS, P92Sounds,
  P92Panic, P92VGA
{$endif}
{$ifdef P92_WASM}
  P92Fonts, P92AssetRegistry,
  P92Conversions,
  P92FPS, P92Logger,
  P92Sounds, P92Timing,
  P92Keyboard, P92Mouse,
  P92TexDraw, P92VGA, P92WasmHost, P92WasmMemMgr, P92InteropBuf, P92Loading
{$endif}
{$ifdef P92_IMMEDIATE_GUI}
  , P92ImmediateGUI
{$endif}
{$ifdef P92_WEBGL}
  , P92WebGL
{$endif}
  ;

{$ifdef P92_SDL2}
var
  hwCursor: longint;
{$endif}

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

{$ifdef P92_WASM}
function GetBootOptionBoolean(key: string): boolean;
begin
  WriteInteropString(key);
  GetBootOptionBoolean := JsGetBootOptionBoolean
end;
{$endif}

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
  engineRunState := ersBoot;

  if DebugEngineRunStates then
    writelog('ersBoot');

{$ifdef P92_WASM}
  InitHeapMgr;
  InitInteropBuffer;
{$endif}
{$ifdef P92_SDL2}
  InitVideoMem(
    bootConfig.width, bootConfig.height,
    getmem(bootConfig.width * bootConfig.height * 4));

  TargetFPS := bootConfig.fps;
  FrameTime := 1000 div TargetFPS;
{$endif}

  InitDeltaTime;
  InitFPSCounter;

  InitAssetRegistry;
  InitSounds;

{$ifdef P92_WEBGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}
{$ifdef P92_SDL2}
  InitSDL;
  InitLogger;
{$endif}

{$ifdef P92_WASM}
  { Read boot options }

  enableDefaultBMFont := GetBootOptionBoolean('defaultFont');
  enableScreenshotHotkey := GetBootOptionBoolean('enableScreenshotHotkey');
{$endif}

{ Request boot font }

{$ifdef P92_WASM}
  SetCGAFontHandle(RequestImage('assets/CGA8x8.png'));
{$endif}
{$ifdef P92_SDL2}
  SetCGAFontHandle(LoadImage('assets/CGA8x8.png'));
{$endif}
end;

procedure InitPreloadState;
begin
{$ifdef P92_WASM}
  FitCanvas;
{$endif}

  engineRunState := ersPreload;

  if DebugEngineRunStates then
    writelog('ersPreload');

{$ifdef P92_SDL2}
  { imgCursor := LoadImage('assets\images\cursor.png'); }
  hwCursor := HwLoadImage('assets\images\cursor.png');
  LoadDefaultFont;
{$endif}

{$ifdef P92_WASM}
  LoadDefaultFont;
  HostCallOnPreload
{$endif}
end;

procedure InitReadyState;
begin
{$ifdef P92_WASM}
  FitCanvas;
{$endif}

  engineRunState := ersReady;

  if DebugEngineRunStates then
    writelog('ersReady');

{$ifdef P92_IMMEDIATE_GUI}
  InitImmediateGUI;
{$endif}
{$ifdef P92_WASM}
  HostCallOnReady
{$endif}
end;

procedure P92Update;
begin
{$ifdef P92_WASM}
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
{$endif}
{$ifdef P92_SDL2}
  HandleSDLEvents;
  UpdateDeltaTime;
  IncrementFPS;
{$endif}
end;

{$ifdef P92_SDL2}
procedure DrawMouse;
begin
  { spr(imgCursor, mouseX, mouseY) }
  HwSpr(hwCursor, mouseX, mouseY)
end;
{$endif}

procedure P92Draw;
begin
{$ifdef P92_WASM}
  cls($FF000000);

  if engineRunState = ersPreload then
    RenderLoadingScreen;
{$endif}
end;

procedure P92AfterDraw;
begin
{$ifdef P92_IMMEDIATE_GUI}
  ResetActiveWidget;
{$endif}

{$ifdef P92_WASM}
  VgaUpload;
  VgaPresent;
{$endif}
{$ifdef P92_WEBGL}
  VgaUpload;
  WebGLPresent;
{$endif}
{$ifdef P92_SDL2}
  VgaUpload;
  { Begin hardware layer }
  DrawMouse;
  VgaPresent
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

{$ifdef P92_SDL2}
procedure P92Cleanup;
begin
  { TODO: free both the imgCursor and the default font }
  { FreeTexture(imgCursor);
  FreeTexture(defaultFont.imgHandle); }

  freemem(getSurfacePtr);
end;

procedure P92Shutdown;
begin
  CloseLogger;
  CleanupSDL
end;


function DefaultP92AppConfig: TP92AppConfig;
var
  newConfig: TP92AppConfig;
begin
  newConfig := default(TP92AppConfig);

  with newConfig do begin
    windowTitle := 'Posit-92 + SDL2 on Windows';
    width := 320;
    height := 200;
    sdlScale := 2;

    enableDefaultFont := true;
    defaultFontPath := 'assets/fonts/nokia_cellphone_fc_8.txt';

    fps := 60;
    enableScreenshotHotkey := true;
  end;

  DefaultP92AppConfig := newConfig
end;

procedure P92Start(const appConfig: TP92AppConfig);
begin
  bootConfig := appConfig;
  enableDefaultBMFont := appConfig.enableDefaultFont;
  enableScreenshotHotkey := appConfig.enableScreenshotHotkey;

  if not assigned(appConfig.Update) then
    PanicHalt('Update callback is required');
  if not assigned(appConfig.Draw) then
    PanicHalt('Draw callback is required');

  P92Boot;

  InitPreloadState;

  if Assigned(appConfig.OnPreload) then
    appConfig.OnPreload;

  InitReadyState;

  if Assigned(appConfig.OnReady) then
    appConfig.OnReady;

  done := false;

  { Game loop }
  lastFrameTime := SDL_GetTicks;

  while not done do begin
    frameTimeNow := SDL_GetTicks;
    elapsed := frameTimeNow - lastFrameTime;

    if elapsed >= FrameTime then begin
      P92Update;

      { User loop }
      appConfig.Update;
      appConfig.Draw;

      P92AfterDraw;

      lastFrameTime := frameTimeNow - (elapsed mod FrameTime) { Carry over extra time }
    end;

    SDL_Delay(1)
  end;

  if Assigned(appConfig.OnCleanup) then
    appConfig.OnCleanup;

  P92Cleanup;
  P92Shutdown
end;
{$endif}

end.

