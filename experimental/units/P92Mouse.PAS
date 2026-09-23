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

function GetMouseX: smallint;
function GetMouseY: smallint;
function GetMouseButton: smallint;

function IsLeftMousePressed: boolean;
function IsRightMousePressed: boolean;

{$IFDEF P92_WASM}
{ Hide system cursor }
procedure HideCursor; external 'env' name 'HideCursor';

{ Show system cursor }
procedure ShowCursor; external 'env' name 'ShowCursor';

procedure UpdateMouse;
{$ENDIF}

{$IFDEF P92_SDL2}
procedure SetMouseX(const value: smallint);
procedure SetMouseY(const value: smallint);
procedure SetMouseButton(const value: smallint);
{$ENDIF}


implementation

var
  mouseX, mouseY, mouseButton: smallint;

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

function IsLeftMousePressed: boolean;
begin
  IsLeftMousePressed := (mouseButton and MouseButtonLeft) <> 0
end;

function IsRightMousePressed: boolean;
begin
  IsRightMousePressed := (mouseButton and MouseButtonRight) <> 0
end;

{$IFDEF P92_WASM}
function JsGetMouseX: smallint; external 'env' name 'JsGetMouseX';
function JsGetMouseY: smallint; external 'env' name 'JsGetMouseY';
function JsGetMouseButton: smallint; external 'env' name 'JsGetMouseButton';

procedure UpdateMouse;
begin
  mouseX := JsGetMouseX;
  mouseY := JsGetMouseY;
  mouseButton := JsGetMouseButton;
end;
{$ENDIF}


{$IFDEF P92_SDL2}
procedure SetMouseX(const value: smallint);
begin
  mouseX := value
end;

procedure SetMouseY(const value:smallint);
begin
  mouseY := value
end;

procedure SetMouseButton(const value:smallint);
begin
  mouseButton := value
end;
{$ENDIF}

end.
