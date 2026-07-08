{
  Unit to contain generic or function calls to the host JS / browser that
  don't have a specific category

  Part of Posit-92 game engine
}

unit P92WasmHost;

interface

{$ifdef P92_WASM}
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
{$endif}

implementation

end.

