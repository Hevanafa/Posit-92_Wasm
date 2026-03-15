{
  Keyboard unit - Part of Posit-92 game engine
  Hevanafa

  Contains a subset of the DOS version
}

unit Keyboard;

{$Mode ObjFPC}
{$H+}{$J-}
{TODO: include all scancodes}

interface

function isKeyDown(const scancode: byte): boolean; external 'env' name 'isKeyDown';

implementation

end.