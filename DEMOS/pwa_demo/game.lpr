library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Fonts, P92Conversions, P92WasmHost, P92FPS,
  P92Tex, P92TexDraw, P92Keyboard, P92Mouse, P92Timing, P92VGA,
  Assets;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;


procedure OnPreload;
begin

end;

procedure OnReady;
begin
  { Initialise game state here }
  hideCursor;
end;

procedure Update;
begin
  if lastEsc <> isKeyDown(SC_ESCAPE) then begin
    lastEsc := isKeyDown(SC_ESCAPE);

    if lastEsc then SignalDone;
  end;

  gameTime := gameTime + DeltaTime;
end;

procedure Draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(texDosuEXE[1], 148, 88)
  else
    spr(texDosuEXE[0], 148, 88);

  s := 'Hello world!';
  w := measureDefault(s);
  PrintDefault(s, (vgaWidth - w) div 2, 120);
end;

exports
  Init,
  OnPreload,
  OnReady,
  Update,
  Draw;

begin
  { Starting point is intentionally left empty }
end.

