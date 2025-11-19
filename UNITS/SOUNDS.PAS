unit Sounds;

interface

procedure playSound(const key: integer); external 'env' name 'playSound';
procedure playMusic(const key: integer); external 'env' name 'playMusic';

implementation

end.
