unit Fullscreen;

interface

procedure toggleFullscreen; external 'env' name 'toggleFullscreen';
function getFullscreenState: boolean; external 'env' name 'getFullscreenState';
procedure fitCanvas; external 'env' name 'fitCanvas';

procedure detectFullscreen; external 'env' name 'detectFullscreen';
procedure endFullscreen; external 'env' name 'endFullscreen';

implementation

end.