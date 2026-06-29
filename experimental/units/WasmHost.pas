{
  Unit to contain generic or function calls to the host JS / browser that
  don't have a specific category

  Part of Posit-92 game engine
}

unit WasmHost;

interface

{ Only used in BeginLoadingState }
procedure RequestAssetLoad; external 'env' name 'RequestAssetLoad';

{ Use this to set `done` to true }
procedure SignalDone; external 'env' name 'SignalDone';

procedure ShowCursor; external 'env' name 'ShowCursor';
procedure HideCursor; external 'env' name 'HideCursor';
procedure FitCanvas; external 'env' name 'FitCanvas';
procedure HideLoadingOverlay; external 'env' name 'HideLoadingOverlay';


implementation

end.

