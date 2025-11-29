library Game;

{$Mode ObjFPC}

uses
  Conv, Keyboard, Mouse, ImmedGui,
  ImgRef, ImgRefFast,
  Sounds, Strings, Timing, VGA,
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
  { Use sound keys }
  actualMusicKey: integer;

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

  actualMusicKey := -1;
end;

function getMusicTimeStr: string;
var
  m, s: integer;
begin
  m := trunc(getMusicTime) div 60;
  s := trunc(getMusicTime) mod 60;
  getMusicTimeStr := i32str(m) + ':' + padStart(i32str(s), 2, '0');
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
  isPlaying: boolean;
begin
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  isPlaying := getMusicPlaying;
  if isPlaying then
    printDefault('Playing', 10, 10)
  else
    printDefault('Paused / Stopped', 10, 10);

{
  s := 'Hello world!';
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, 120);
}
  printDefault(getMusicTimeStr, 100, 124);

  if isPlaying then begin
    if ImageButton(129, 116, imgPause, imgPause, imgPause) then
      pauseMusic;
  end else
    if ImageButton(129, 116, imgPlay, imgPlay, imgPlay) then begin
      if actualMusicKey < 0 then begin
        { Starting new }
        actualMusicKey := BgmPhonk;
        playMusic(BgmPhonk)
      end else
        { Resuming }
        playMusic(actualMusicKey);
    end;
  
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

