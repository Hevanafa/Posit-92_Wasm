library Game;

{$Mode ObjFPC}
{$J-}

uses
  Conv, Fullscreen, Loading,
  Keyboard, Mouse, ImmedGui,
  ImgRef, ImgRefFast, Logger,
  Sounds, Strings, Timing,
  WasmMemMgr, VGA,
  Assets;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );

const
  SC_ESC = $01;
  SC_SPACE = $39;

  CornflowerBlue = $FF6495ED;

  { Sound keys -- must be the same as on JS side }
  BgmClassic = 1;

var
  lastEsc: boolean;

  { Game state variables }
  actualGameState: TGameStates;
  gameTime: double;
  { Use sound keys }
  actualMusicKey: integer;
  
  seekerState: TSliderState;

  repeatState: TCheckboxState;
  lastRepeat: boolean;

  isMuted: boolean;
  volumeState: TSliderState;
  lastVolume: integer;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';
procedure hideCursor; external 'env' name 'hideCursor';
procedure hideLoadingOverlay; external 'env' name 'hideLoadingOverlay';
procedure loadAssets; external 'env' name 'loadAssets';

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure beginLoadingState;
begin
  actualGameState := GameStateLoading;
  fitCanvas;
  loadAssets
end;

procedure beginPlayingState;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  hideCursor;

  initImmediateGUI;
  guiSetFont(defaultFont, defaultFontGlyphs);

  actualMusicKey := -1;
  isMuted := false;

  seekerState.value := 0;

  repeatState.checked := true;
  lastRepeat := repeatState.checked;

  volumeState.value := 25;
  lastVolume := volumeState.value;
  setMusicVolume(volumeState.value / 100.0)
end;


procedure init;
begin
  initHeapMgr;
  initDeltaTime;
end;

procedure afterInit;
begin
  beginPlayingState
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
  updateGUIMousePoint;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);
    if lastEsc then signalDone;
  end;

  gameTime := gameTime + dt;

  if lastRepeat <> repeatState.checked then begin
    lastRepeat := repeatState.checked;
    setMusicRepeat(repeatState.checked)
  end;

  if lastVolume <> volumeState.value then begin
    lastVolume := volumeState.value;
    setMusicVolume(volumeState.value / 100.0)
  end;

  handleMusicRepeat(BgmClassic);

  resetWidgetIndices
end;

procedure draw;
var
  isPlaying: boolean;

  duration, actualTime, seekTime: double;
  dragState: TSliderDragState;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;

  cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 48)
  else
    spr(imgDosuEXE[0], 148, 48);

  Checkbox('Repeat', 50, 125, repeatState);

  isPlaying := getMusicPlaying;
  if isPlaying then
    printDefault('Playing', 10, 10)
  else
    printDefault('Paused / Stopped', 10, 10);

  { Music Seeker }
  duration := getMusicDuration;
  actualTime := getMusicTime;

  dragState := SliderDrag(64, 94, 192, seekerState, 0, 100);

  if dragState = SliderReleased then begin
    { writeLog('Attempting to release slider'); }
    seekTime := seekerState.value / 100.0 * duration;
    { writeLogF32(seekTime); }

    seekMusic(seekTime)
  end;

  if (dragState <> SliderDragging) and (duration > 0.0) then
    seekerState.value := round(actualTime / duration * 100.0);

  { Music time }
  printDefault(getMusicTimeStr, 100, 124);

  { Play / pause button }
  if isPlaying then begin
    if ImageButton(129, 116, imgPause, imgPause, imgPause) then
      pauseMusic;
  end else
    if ImageButton(129, 116, imgPlay, imgPlay, imgPlay) then begin
      if actualMusicKey < 0 then begin
        { Starting new }
        actualMusicKey := BgmClassic;
        playMusic(BgmClassic)
      end else
        { Resuming }
        playMusic(actualMusicKey);
    end;
  
  if ImageButton(161, 116, imgStop, imgStop, imgStop) then
    stopMusic;

  { Volume control }
  if isMuted or (volumeState.value = 0) then
    spr(imgVolumeOff, 202, 123)
  else
    spr(imgVolumeOn, 202, 123);

  Slider(217, 125, 64, volumeState, 0, 100);

  resetActiveWidget;

  drawMouse;
  vgaFlush
end;

exports
  beginLoadingState,
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.

