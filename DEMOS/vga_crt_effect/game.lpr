library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Colour, P92Conversions, P92Maths,
  P92Keyboard, P92Mouse, P92Tex, P92TexDraw,
  P92PostProc, P92Timing, P92VGA, P92WasmHost,
  Assets;

const
  Black = $FF181818;
  DarkGreen = $FF00AA00;
  Green = $FF55FF55;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;


procedure OnPreload;
begin
  { TODO: Load the assets }
end;

procedure OnReady;
begin
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
  bg: longword;
  randomCoeff: double;
  brightness, strength: double;
begin
  { Assign a randomised coefficient }
  { brightness := 1.0 + sin(getTimer * 5.0) * 0.2; }
  randomCoeff := random - 0.5;
  brightness := 1.0 + randomCoeff * 0.3;

  bg := HSVtoRGB(1 / 3.0, 1.0, 0.4 + 0.27 * (0.5 + randomCoeff));
  cls(bg);
  { cls(DarkGreen); }

  spr(texPipBoy,
    (vgaWidth - GetTexWidth(texPipBoy)) div 2,
    (vgaHeight - GetTexHeight(texPipBoy)) div 2);

  DrawFPS;
  DrawMouse;

  { Apply post-processing chain }
  ApplyFullPhosphor(1);
  ApplyFullChromabe;
  ApplyFullSubtleScanlines;

  strength := 0.4 * brightness;
  ApplyFullVignette(FalloffTypeEaseOutQuad, strength);

  VGAPresent
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

