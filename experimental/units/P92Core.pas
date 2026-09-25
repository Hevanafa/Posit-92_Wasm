unit P92Core;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }

interface

uses P92AssetHandles;

{$IFDEF P92_WASM}
const
  Posit92Version = '0.3.4';

type
  TCallback = procedure;

  TP92AppConfig = record
    { default: "game" }
    CanvasID: string;

    { Default: "2d"
      Possible options: "2d" | "webgl" | "experimental-webgl" }
    Renderer: string;

    { default: 320 }
    BufferWidth: smallint;

    { default: 200 }
    BufferHeight: smallint;

    { default: 60
      0 makes it the same refresh rate as the monitor }
    TargetFPS: smallint;

    { default: true }
    LoadDefaultBMFont: boolean;
    { overridable, used together with `LoadDefaultBMFont` }
    DefaultBMFontPath: string;

    { default: true }
    LoadDefaultCursor: boolean;

    { default: true }
    EnableScreenshotHotkey: boolean;

    { default: false }
    EnableDrawFPS: boolean;
  end;
{$ENDIF}

{$IFDEF P92_SDL2}
const
  Posit92Version = '0.3';

type
  TCallback = procedure;

  TP92AppConfig = record
    { SDL2 }

    WindowTitle: string;
    SDLScale: smallint;

    { Features }

    BufferWidth: smallint;
    BufferHeight: smallint;

    LoadDefaultBMFont: boolean;
    DefaultBMFontPath: string;

    TargetFPS: smallint;
    EnableScreenshotHotkey: boolean;

    LoadDefaultCursor: boolean;

    { Callbacks }

    OnPreload: TCallback;
    OnReady: TCallback;
    Update: TCallback;
    Draw: TCallback;
    OnCleanup: TCallback;
  end;
{$ENDIF}

{$IFDEF P92_WASM}
function GetBootFontHandle: TTextureHandle;
procedure SetBootFontHandle(const value: TTextureHandle);

function IsEngineReady: boolean; public name 'IsEngineReady';
procedure HostCallOnPreload; external 'env' name 'HostCallOnPreload';
procedure HostCallOnReady; external 'env' name 'HostCallOnReady';
{$ENDIF}

function GetBootConfig: TP92AppConfig;

procedure P92Boot; public name 'P92Boot';
procedure P92Update; public name 'P92Update';
procedure P92Draw; public name 'P92Draw';
procedure P92AfterDraw; public name 'P92AfterDraw';

procedure PrintChar(const c: char; const x, y: smallint);
procedure Print(const txt: string; const x, y: smallint);

procedure PrintWrap(const txt: string; x, y, wrapWidth: smallint);

procedure PrintCharTint(const c: char; const x, y: smallint; const colour: longword);
procedure PrintTint(const txt: string; const x, y: smallint; const colour: longword);

function DefaultP92AppConfig: TP92AppConfig;
procedure P92Start(const appConfig: TP92AppConfig);

procedure DrawFPS;


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
  P92Fonts, P92AssetRegistry, P92WasmHeap, P92Conversions,
  P92FPS, P92Logger,
{$ifdef P92_ENABLE_SOUNDS}
  P92Sounds,
{$endif}
  P92Timing,
  P92Keyboard, P92Mouse,
  P92TexDraw, P92VGA, P92WasmHost, P92WasmMemMgr, P92InteropBuf, P92Loading
{$endif}
{$ifdef P92_IMGUI}
  , P92IMGUI
{$endif}
{$ifdef P92_WEBGL}
  , P92WebGL
{$endif}
  ;

{$IFDEF P92_WASM}
var
  texCursor: TTextureHandle;
{$ENDIF}

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
  DefaultCursorPath = 'assets/images/cursor.png';
  DebugEngineRunStates = false;

  BootFontGlyphWidth = 8;
  BootFontGlyphHeight = 8;


var
  bootConfig: TP92AppConfig;
  engineRunState: TEngineRunStates;

  { Default boot font }
  BootFontHandle: TTextureHandle;

  { Used by screenshot }
  lastF2: boolean;

  fpsTop, fpsRight: smallint;


function GetBootConfig: TP92AppConfig;
begin
  GetBootConfig := bootConfig
end;

function GetBootFontHandle: TTextureHandle;
begin
  GetBootFontHandle := BootFontHandle
end;

procedure SetBootFontHandle(const value: TTextureHandle);
begin
  BootFontHandle := value
end;

function IsEngineReady: boolean;
begin
  IsEngineReady := engineRunState = ersReady
end;

{$IFDEF P92_WASM}
procedure InitWasmRuntime;
var
  heapRegionStart: pointer;
begin
  JsInitWasmMemory(WasmMemorySize);

  InitVideoMem(Pointer(StackSize), bootConfig.BufferWidth, bootConfig.BufferHeight);

  heapRegionStart := pointer(StackSize + GetVideoMemSize);
  InitHeapRegion(heapRegionStart);

  InitHeapMgr;
  InitInteropBuffer;

  WriteInteropString(bootConfig.CanvasID);
  JsCreateCanvas(bootConfig.BufferWidth, bootConfig.BufferHeight);

  WriteInteropString(bootConfig.Renderer);
  JsInitCanvasCtx;

  JsSetTargetFPS(bootConfig.TargetFPS);
end;
{$ENDIF}

procedure P92Boot;
begin
{$ifdef P92_WASM}
  InitWasmRuntime;
{$endif}

  engineRunState := ersBoot;

  if DebugEngineRunStates then
    WriteLog('ersBoot');

{$ifdef P92_SDL2}
  InitVideoMem(
    GetMem(GetBootConfig.BufferWidth * GetBootConfig.BufferHeight * 4),
    bootConfig.BufferWidth, bootConfig.BufferHeight);

  TargetFPS := bootConfig.TargetFPS;
  FrameTime := 1000 div TargetFPS;
{$endif}

  InitDeltaTime;

  InitFPSCounter;
  fpsTop := 0;
  fpsRight := VGAWidth * 3 div 4;

  InitAssetRegistry;

{$ifdef P92_ENABLE_SOUNDS}
  InitSounds;
{$endif}
{$ifdef P92_WEBGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}
{$ifdef P92_SDL2}
  InitSDL;
  InitLogger;
{$endif}

  { Request boot font }
  SetBootFontHandle(RequestImage('assets/CGA8x8.png'));
end;

procedure InitPreloadState;
begin
{$ifdef P92_WASM}
  FitCanvas;
{$endif}

  engineRunState := ersPreload;

  if DebugEngineRunStates then
    WriteLog('ersPreload');

{$ifdef P92_SDL2}
  if bootConfig.LoadDefaultCursor then
    { imgCursor := LoadImage('assets\images\cursor.png'); }
    hwCursor := HwRequestImage('assets\images\cursor.png')
  else
    hwCursor := 0;
{$endif}

  if bootConfig.LoadDefaultCursor then
    texCursor := RequestImage(DefaultCursorPath);

  if bootConfig.LoadDefaultBMFont then
    LoadDefaultBMFont;
  { else
    WriteLog('InitPreloadState: Skipped loading the default BMFont'); }

{$ifdef P92_WASM}
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
    WriteLog('ersReady');

{$IFDEF P92_IMGUI}
{$IFDEF P92_WASM}
  InitImmediateGUI(bootConfig.LoadDefaultBMFont);
{$ENDIF}
{$IFDEF P92_SDL2}
  InitImmediateGUI(bootConfig.LoadDefaultBMFont);
{$ENDIF}
{$ENDIF}

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
{$ifdef P92_IMGUI}
    ResetWidgetIndices;

    UpdateGUILastMouseButton;
    UpdateMouse;
    UpdateGUIMouseState;
{$else}
    UpdateMouse;
{$endif}

    if bootConfig.enableScreenshotHotkey then begin
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

procedure DrawMouse;
begin
{$IFDEF P92_WASM}
  Spr(texCursor, GetMouseX, GetMouseY)
{$ENDIF}

{$IFDEF P92_SDL2}
  HwSpr(hwCursor, GetMouseX, GetMouseY)
{$ENDIF}
end;

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
{$ifdef P92_IMGUI}
  ResetActiveWidget;
{$endif}

{$IFDEF P92_WEBGL}
  DrawMouse;

  if bootConfig.EnableDrawFPS then
    DrawFPS;

  VGAUpload;
  WebGLPresent;
{$ELSE}
  DrawMouse;

  if bootConfig.EnableDrawFPS then
    DrawFPS;

  VGAUpload;
  VGAPresent;
{$ENDIF}

{$ifdef P92_SDL2}
  if bootConfig.EnableDrawFPS then
    DrawFPS;

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
    BootFontHandle,
    col * BootFontGlyphWidth,
    row * BootFontGlyphHeight,
    BootFontGlyphWidth,
    BootFontGlyphHeight,
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
    inc(left, BootFontGlyphWidth)
  end;
end;

procedure PrintWrap(const txt: string; x, y, wrapWidth: smallint);
var
  c: char;
  { relative to x }
  left: smallint;
begin
  left := 0;

  for c in txt do begin
    if c = #10 then begin
      left := 0;
      inc(y, BootFontGlyphWidth);
      continue;
    end;

    if c = #13 then continue;

    PrintChar(c, x + left, y);
    inc(left, BootFontGlyphWidth);

    if left >= wrapWidth then begin
      left := 0;
      inc(y, BootFontGlyphHeight);
    end;
  end;
end;

procedure PrintCharTint(const c: char; const x, y: smallint; const colour: longword);
var
  row, col: smallint;
begin
  if not (ord(c) in [1..255]) then exit;

  row := ord(c) div 16;
  col := ord(c) mod 16;

  SprRegionTint(
    BootFontHandle,
    col * BootFontGlyphWidth,
    row * BootFontGlyphHeight,
    BootFontGlyphWidth,
    BootFontGlyphHeight,
    x, y, colour)
end;

procedure PrintTint(const txt: string; const x, y: smallint; const colour: longword);
var
  c: char;
  left: smallint;
begin
  left := x;

  for c in txt do begin
    PrintCharTint(c, left, y, colour);
    inc(left, BootFontGlyphWidth)
  end;
end;

procedure DrawFPS;
begin
  if bootConfig.LoadDefaultBMFont then
    PrintDefault('FPS: ' + I32Str(GetLastFPS), fpsRight, fpsTop)
  else
    Print('FPS: ' + I32Str(GetLastFPS), fpsRight, fpsTop);

{$ifdef DEBUG_FPS}
  print('lastFPS: ' + i32str(lastFPS), VgaWidth - 160, 16);
  print('actualFPS: ' + i32str(actualFPS), VgaWidth - 160, 24);
  print('lastFPSTime: ' + f32str(lastFPSTime), VgaWidth - 160, 32);
{$endif}
end;

{$IFDEF P92_WASM}
function DefaultP92AppConfig: TP92AppConfig;
var
  newConfig: TP92AppConfig;
begin
  newConfig := default(TP92AppConfig);

  newConfig.CanvasID := 'game';
  newConfig.BufferWidth := 320;
  newConfig.BufferHeight := 200;

  newConfig.Renderer:= '2d';
  newConfig.TargetFPS := 60;

  newConfig.LoadDefaultBMFont := true;
  newConfig.DefaultBMFontPath := 'assets/fonts/p92_sans_8_regular.txt';

  newConfig.LoadDefaultCursor := true;
  newConfig.EnableScreenshotHotkey := true;
  newConfig.EnableDrawFPS := false;

  DefaultP92AppConfig := newConfig;
end;

procedure P92Start(const appConfig: TP92AppConfig);
begin
  bootConfig := appConfig;
  P92Boot
end;
{$ENDIF}

{$IFDEF P92_SDL2}
procedure P92Cleanup;
begin
  { TODO: free both the imgCursor and the default font }
  { FreeTexture(imgCursor);
  FreeTexture(defaultFont.imgHandle); }

  freemem(BorrowSurfacePtr);
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
    WindowTitle := 'Posit-92 + SDL2 on Windows';
    SDLScale := 2;

    BufferWidth := 320;
    BufferHeight := 200;

    LoadDefaultBMFont := true;
    DefaultBMFontPath := 'assets\fonts\p92_sans_8_regular.txt';

    TargetFPS := 60;
    EnableScreenshotHotkey := true;

    LoadDefaultCursor := true;
  end;

  DefaultP92AppConfig := newConfig
end;

procedure P92Start(const appConfig: TP92AppConfig);
begin
  bootConfig := appConfig;

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
{$ENDIF}


end.

