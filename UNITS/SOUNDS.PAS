unit Sounds;

interface

procedure playSound(const key: integer); external 'env' name 'playSound';
procedure playMusic(const key: integer); external 'env' name 'playMusic';
procedure stopMusic; external 'env' name 'stopMusic';


implementation

end.
