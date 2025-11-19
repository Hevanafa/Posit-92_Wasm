unit Mouse;

{$Mode ObjFPC}

interface

var
  mouseX, mouseY: integer;

implementation

function getMouseX: integer; external 'env' name 'getMouseX';
function getMouseY: integer; external 'env' name 'getMouseY';
function getMouseButton: integer; external 'env' name 'getMouseButton';

procedure updateMouse;
begin
  mouseX := getMouseX;
  mouseY := getMouseY;
  mouseButton := getMouseButton;
end;