{
  Fullscreen demo
  Part of Posit-92 game engine
  Mixins: bmfont, sound
}

library Game;

{$Mode ObjFPC}
{$J-}  { Switch off assignments to typed constants }

uses
  P92Core, P92Fonts, P92WasmHost,
  P92Conversions, P92FPS,
  P92Tex, P92TexDraw,
  P92Keyboard, P92Mouse,
  P92ImmediateGUI, P92Timing,
  P92VGA,
  Assets;

var
  lastEsc, lastSpacebar: boolean;

  { Init your game state here }
  gameTime: double;

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure OnPreload;
begin
  { TODO: Load the assets }
end;

procedure OnReady;
begin
  hideCursor;

  { Initialise game state here }
  gameTime := 0.0;
end;


procedure Update;
begin
  if lastSpacebar <> isKeyDown(SC_SPACE) then begin
    lastSpacebar := isKeyDown(SC_SPACE);
    if lastSpacebar then toggleFullscreen;
  end;

  gameTime := gameTime + DeltaTime
end;

procedure Draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := 'Press Spacebar to toggle fullscreen';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  if ImageButton(
    vgaWidth - 30, vgaHeight - 30,
    imgFullscreen, imgFullscreen, imgFullscreen) then
    toggleFullscreen;

  printDefault('Fullscreen? ' + boolStr(getFullscreenState), 10, 30);

  resetActiveWidget;
  DrawMouse;
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

