{
  Keyboard unit
  Part of Posit-92 game engine

  Contains a subset of the DOS version
}

unit Keyboard;

{$Mode ObjFPC}
{$H+}{$J-}

interface

{ Requires the Scancodes unit }
function isKeyDown(const scancode: byte): boolean; external 'env' name 'isKeyDown';

implementation

end.