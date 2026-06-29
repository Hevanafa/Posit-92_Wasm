unit WasmHost;

interface

procedure RequestAssetLoad; external 'env' name 'RequestAssetLoad';

{ Use this to set `done` to true }
procedure SignalDone; external 'env' name 'SignalDone';

procedure ShowCursor; external 'env' name 'ShowCursor';
procedure HideCursor; external 'env' name 'HideCursor';
procedure FitCanvas; external 'env' name 'FitCanvas';

implementation

end.

