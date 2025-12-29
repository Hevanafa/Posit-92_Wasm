{
  Keyboard unit - Part of Posit-92 game engine
  Hevanafa

  Contains a subset of the DOS version
}

unit Keyboard;

{$Mode TP}

interface

function isKeyDown(const scancode: byte): boolean; external 'env' name 'isKeyDown';

implementation

end.