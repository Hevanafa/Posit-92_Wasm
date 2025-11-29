library Game;

{$Mode ObjFPC}

uses
  Keyboard, Mouse,
  ImmedGui,
  ImgRef, ImgRefFast,
  Sounds, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

  { Sound keys -- must be the same as on JS side }
  BgmPhonk = 1;

var
  lastEsc: boolean;

  { Init your game state here }
  gameTime: double;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;


procedure init;
begin
  initBuffer;
  initDeltaTime;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;

  initImmediateGUI;
  guiSetFont(defaultFont, defaultFontGlyphs);
end;

procedure update;
begin
  updateDeltaTime;

  updateGUILastMouseButton;
  updateMouse;
  updateGUIMouseZone;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then signalDone;
  end;

  gameTime := gameTime + dt;

  resetWidgetIndices
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);

  if ImageButton(129, 116, imgPlay, imgPlay, imgPlay) then
    playMusic(BgmPhonk);
  
  if ImageButton(161, 116, imgStop, imgStop, imgStop) then
    stopMusic;

  resetActiveWidget;
  drawMouse;
  flush
end;

exports
  { Main game procedures }
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

