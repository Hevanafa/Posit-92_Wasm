{
  Mouse unit
  Part of Posit-92 game engine
  By Hevanafa

  Contains a subset of the DOS version
}

unit P92Mouse;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }

interface

const
  MouseButtonNone = 0;
  MouseButtonLeft = 1;
  MouseButtonRight = 2;
  MouseButtonBoth = 3;

{$ifdef P92_WASM}
{ Hide system cursor }
procedure HideCursor; external 'env' name 'HideCursor';

{ Show system cursor }
procedure ShowCursor; external 'env' name 'ShowCursor';

function GetMouseX: smallint;
function GetMouseY: smallint;
function GetMouseButton: smallint;

procedure UpdateMouse;
{$endif}


implementation

var
  mouseX, mouseY, mouseButton: smallint;

{$ifdef P92_WASM}
function JsGetMouseX: smallint; external 'env' name 'JsGetMouseX';
function JsGetMouseY: smallint; external 'env' name 'JsGetMouseY';
function JsGetMouseButton: smallint; external 'env' name 'JsGetMouseButton';

function GetMouseX: smallint;
begin
  GetMouseX := mouseX
end;

function GetMouseY: smallint;
begin
  GetMouseY := mouseY
end;

function GetMouseButton: smallint;
begin
  GetMouseButton := mouseButton
end;

procedure UpdateMouse;
begin
  mouseX := JsGetMouseX;
  mouseY := JsGetMouseY;
  mouseButton := JsGetMouseButton;
end;
{$endif}

end.
