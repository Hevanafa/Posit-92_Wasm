unit Fullscreen;

interface

procedure toggleFullscreen; external 'env' name 'toggleFullscreen';
function getFullscreenState: boolean; external 'env' name 'getFullscreenState';

implementation

end.