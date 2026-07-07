library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Fonts, P92WasmHost, P92AssetRegistry,
  P92Conversions, P92FPS, P92Graphics,
  P92Tex, P92TexDraw,
  P92Keyboard, P92Mouse,
  P92Logger, P92Sounds,
  P92Timing, P92VGA,
  Assets;

var
  lastEsc, lastSpacebar: boolean;
  lastD1, lastD2, lastD3, lastD4, lastD5: boolean;

  { Game state variables }
  gameTime: double;

procedure DrawFPS;
begin
  PrintDefault('FPS:' + I32Str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  Spr(imgCursor, mouseX, mouseY)
end;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');
  imgDosuExe[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuExe[1] := RequestImage('assets/images/dosu_2.png');

  sfxBwonk := RequestSound('assets/sfx/bwonk.ogg');
  sfxBite := RequestSound('assets/sfx/bite.ogg');
  sfxBonk := RequestSound('assets/sfx/bonk.ogg');
  sfxStrum := RequestSound('assets/sfx/strum.ogg');
  sfxSlip := RequestSound('assets/sfx/slip.ogg');
end;

procedure OnReady;
begin
  HideCursor;
  gameTime := 0.0;
end;


procedure PlayRandomSFX;
begin
  PlaySound(1 + random(sfxSlip))
end;


procedure Update;
begin
  UpdateDeltaTime;
  IncrementFPS;

  UpdateMouse;

  { Your Update logic here }
  if lastEsc <> IsKeyDown(SC_ESCAPE) then begin
    lastEsc := IsKeyDown(SC_ESCAPE);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      SignalDone
    end;
  end;

  if lastSpacebar <> IsKeyDown(SC_SPACE) then begin
    lastSpacebar := IsKeyDown(SC_SPACE);

    if lastSpacebar then PlayRandomSFX;
  end;

  if lastD1 <> IsKeyDown(SC_1) then begin
    lastD1 := IsKeyDown(SC_1);
    if lastD1 then PlaySound(1);
  end;

  if lastD2 <> IsKeyDown(SC_2) then begin
    lastD2 := IsKeyDown(SC_2);
    if lastD2 then PlaySound(2);
  end;

  if lastD3 <> IsKeyDown(SC_3) then begin
    lastD3 := IsKeyDown(SC_3);
    if lastD3 then PlaySound(3);
  end;

  if lastD4 <> IsKeyDown(SC_4) then begin
    lastD4 := IsKeyDown(SC_4);
    if lastD4 then PlaySound(4);
  end;

  if lastD5 <> IsKeyDown(SC_5) then begin
    lastD5 := IsKeyDown(SC_5);
    if lastD5 then PlaySound(5);
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

  s := '1, 2, 3, 4, 5 - Play sound';
  w := MeasureDefault(s);
  PrintDefault(s, (vgaWidth - w) div 2, 120);

  s := 'Spacebar - Play a random sound';
  w := MeasureDefault(s);
  PrintDefault(s, (vgaWidth - w) div 2, 130);

  DrawMouse;
  DrawFPS;

  VgaUpload;
  VgaPresent
end;

exports
  { Main game procedures }
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

