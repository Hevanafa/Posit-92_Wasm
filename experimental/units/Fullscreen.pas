unit Fullscreen;

interface

procedure ToggleFullscreen; external 'env' name 'ToggleFullscreen';
function GetFullscreenState: boolean; external 'env' name 'GetFullscreenState';
procedure FitCanvas; external 'env' name 'FitCanvas';
procedure EndFullscreen; external 'env' name 'EndFullscreen';

implementation

end.
