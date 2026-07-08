{
  Screenshot demo
  Part of Posit-92 game engine
  Mixins: bmfont, sound
}

library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Fonts, P92AssetRegistry, P92WasmHost,
  P92Keyboard, P92Mouse,
  P92TexDraw,
  P92Timing, P92VGA,
  Assets;

const
  CornflowerBlue = $FF6495ED;

var
  { Game state variables }
  gameTime: double;


procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');

  imgDosuExe[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuExe[1] := RequestImage('assets/images/dosu_2.png');
end;

procedure OnReady;
begin
  hideCursor;

  { Initialise game state here }
  gameTime := 0.0;
end;


procedure Update;
begin
  if isKeyDown(SC_ESCAPE) then signalDone;

  { Handle game state updates }
  gameTime := gameTime + DeltaTime
end;

procedure Draw;
begin
  cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  printDefaultCentred('Press F2 to take a screenshot', vgaWidth div 2, 120);

  DrawMouse
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.
