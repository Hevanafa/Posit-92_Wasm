library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Fonts, P92Conversions, P92WasmHost, P92FPS, P92AssetRegistry,
  P92Tex, P92TexDraw, P92Keyboard, P92Mouse, P92Timing, P92VGA,
  Assets;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;


procedure OnPreload;
begin
  texSpecimenP92[0] := RequestImage('assets/images/specimen_p-92_1.png');
  texSpecimenP92[1] := RequestImage('assets/images/specimen_p-92_2.png');
end;

procedure OnReady;
begin
  { Initialise game state here }
  HideCursor;
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
    spr(texSpecimenP92[1], 148, 88)
  else
    spr(texSpecimenP92[0], 148, 88);

  s := 'Hello world!';
  w := measureDefault(s);
  PrintDefault(s, (vgaWidth - w) div 2, 120);
end;

procedure Init;
var
  appConfig: TP92AppConfig;
begin
  appConfig := DefaultP92AppConfig;

  P92Start(appConfig);
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

