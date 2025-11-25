unit Mouse;

{$Mode TP}

interface

const
  MouseButtonNone = 0;
  MouseButtonLeft = 1;
  MouseButtonRight = 2;
  MouseButtonBoth = 3;

var
  mouseX, mouseY, mouseButton: integer;

{ Hide system cursor }
procedure hideCursor; external 'env' name 'hideCursor';
{ Show system cursor }
procedure showCursor; external 'env' name 'showCursor';

procedure updateMouse;


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

end.
