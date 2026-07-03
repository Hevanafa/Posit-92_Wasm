{
  Mouse unit
  Part of Posit-92 game engine
  By Hevanafa

  Contains a subset of the DOS version
}

unit P92Mouse;

{$Mode ObjFPC}
{$H+}{$J-}

interface

const
  MouseButtonNone = 0;
  MouseButtonLeft = 1;
  MouseButtonRight = 2;
  MouseButtonBoth = 3;

var
  mouseX, mouseY, mouseButton: smallint;

{$ifdef WASM}
{ Hide system cursor }
procedure HideCursor; external 'env' name 'HideCursor';
{ Show system cursor }
procedure ShowCursor; external 'env' name 'ShowCursor';
procedure UpdateMouse;
{$endif}


implementation

{$ifdef WASM}
function GetMouseX: smallint; external 'env' name 'GetMouseX';
function GetMouseY: smallint; external 'env' name 'GetMouseY';
function GetMouseButton: smallint; external 'env' name 'GetMouseButton';

procedure UpdateMouse;
begin
  mouseX := GetMouseX;
  mouseY := GetMouseY;
  mouseButton := GetMouseButton;
end;
{$endif}

end.
