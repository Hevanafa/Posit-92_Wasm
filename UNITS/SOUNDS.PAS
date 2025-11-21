unit Sounds;

{$Mode TP}

interface

procedure playSound(const key: longint); external 'env' name 'playSound';
procedure playMusic(const key: longint); external 'env' name 'playMusic';
procedure setSoundVolume(const key: longint; const volume: double); external 'env' name 'setSoundVolume';
procedure setMusicVolume(const volume: double); external 'env' name 'setMusicVolume';
procedure stopMusic; external 'env' name 'stopMusic';


implementation

end.
