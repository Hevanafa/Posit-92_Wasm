unit P92Core;

{$Mode ObjFPC}
{$H-}
{$J+}

interface

type
  TEngineRunStates = (
    ersBoot,
    ersLoading,
    ersPlaying
  );

var
  engineRunState: TEngineRunStates;

procedure InitEngine; public name 'InitEngine';
procedure InitLoadingState; public name 'InitLoadingState';
procedure SetCGAFontHandle(value: longint); public name 'SetCGAFontHandle';


implementation

uses
  WasmMemMgr, Logger, InteropBuf, P92AssetRegistry, SoftwareTexDraw, Timing
{$ifdef UseWebGL}
  , WebGL
{$endif}
  ;

var
  cgaFontHandle: longint;

procedure InitEngine;
begin
  engineRunState := ersBoot;

  InitHeapMgr;
  InitInteropBuffer;
  InitDeltaTime;
  InitAssetRegistry;

{$ifdef UseWebGL}
  SetupWebGLViewport;
  SetupWebGLShaders;
{$endif}
end;

procedure InitLoadingState;
begin
  engineRunState := ersLoading;
  writelog('Entered loading state');
end;

procedure SetCGAFontHandle(value: longint);
begin
  cgaFontHandle := value
end;

procedure print(txt: string; x, y: smallint);
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

