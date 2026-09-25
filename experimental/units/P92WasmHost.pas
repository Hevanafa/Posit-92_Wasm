{
  Unit to contain generic or function calls to the host JS / browser that
  don't have a specific category

  Part of Posit-92 game engine
}

unit P92WasmHost;

interface

{$IFDEF P92_WASM}
procedure JsInitWasmMemory(requiredSize: longword); external 'env' name 'JsInitWasmMemory';
procedure JsSetTitle; external 'env' name 'JsSetTitle';
procedure JsCreateCanvas(width: integer; height: integer); external 'env' name 'JsCreateCanvas';
procedure JsInitCanvasCtx; external 'env' name 'JsInitCanvasCtx';
procedure JsSetTargetFPS(fps: smallint); external 'env' name 'JsSetTargetFPS';

procedure SetWindowTitle(const newTitle: string);

{ Use this to set `done` to true }
procedure SignalDone; external 'env' name 'SignalDone';

procedure ShowCursor; external 'env' name 'ShowCursor';
procedure HideCursor; external 'env' name 'HideCursor';
procedure FitCanvas; external 'env' name 'FitCanvas';
procedure HideLoadingOverlay; external 'env' name 'HideLoadingOverlay';

procedure ToggleFullscreen; external 'env' name 'ToggleFullscreen';
function GetFullscreenState: boolean; external 'env' name 'GetFullscreenState';
procedure EndFullscreen; external 'env' name 'EndFullscreen';

procedure JsTakeScreenshot; external 'env' name 'JsTakeScreenshot';
{$ENDIF}


implementation

{$IFDEF P92_WASM}

uses P92InteropBuf;

procedure SetWindowTitle(const newTitle: string);
begin
  WriteInteropString(newTitle);
  JsSetTitle
end;

{$ENDIF}

end.

