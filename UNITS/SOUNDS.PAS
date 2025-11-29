unit Sounds;

{$Mode TP}

interface

procedure playSound(const key: longint); external 'env' name 'playSound';

procedure playMusic(const key: longint); external 'env' name 'playMusic';
function getMusicRepeat: boolean; external 'env' name 'getMusicRepeat';
procedure setMusicRepeat(const value: boolean); external 'env' name 'setMusicRepeat';
procedure pauseMusic; external 'env' name 'pauseMusic';
procedure stopMusic; external 'env' name 'stopMusic';

{ t: time in seconds }
procedure seekMusic(const t: double); external 'env' name 'seekMusic';
function getMusicPlaying: boolean; external 'env' name 'getMusicPlaying';
function getMusicTime: double; external 'env' name 'getMusicTime';
function getMusicDuration: double; external 'env' name 'getMusicDuration';

procedure setSoundVolume(const key: longint; const volume: double); external 'env' name 'setSoundVolume';
procedure setMusicVolume(const volume: double); external 'env' name 'setMusicVolume';


implementation

end.
