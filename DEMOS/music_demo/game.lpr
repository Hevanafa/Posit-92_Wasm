{
  Title: Music demo
  Mixins: sounds
}

library Game;

{$Mode ObjFPC}
{$J-}

uses
  P92Core, P92Fonts, P92WasmHost, P92AssetRegistry,
  P92Conversions, P92Loading, P92Logger,
  P92Keyboard, P92Mouse,
  P92ImmediateGUI,
  P92Tex, P92TexDraw,
  P92Sounds, P92Strings,
  P92Timing, P92VGA,
  Assets;

const
  CornflowerBlue = $FF6495ED;

var
  lastEsc: boolean;

  { Game state variables }
  gameTime: double;
  { Use sound keys }
  actualMusicKey: integer;
  
  seekerState: TSliderState;

  repeatState: TCheckboxState;
  lastRepeat: boolean;

  isMuted: boolean;
  volumeState: TSliderState;
  lastVolume: integer;

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');
  imgDosuEXE[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuEXE[1] := RequestImage('assets/images/dosu_2.png');

  imgPlay := RequestImage('assets/images/play.png');
  imgStop := RequestImage('assets/images/stop.png');
  imgPause := RequestImage('assets/images/pause.png');

  imgVolumeOn := RequestImage('assets/images/volume_on.png');
  imgVolumeOff := RequestImage('assets/images/volume_off.png');

  bgmClassic := RequestSound('assets/bgm/Georges Bizet - Les Toreadors from Carmen Suite No. 1.ogg');
end;

procedure OnReady;
begin
  { Initialise game state here }
  hideCursor;

  InitImmediateGUI;

  actualMusicKey := -1;
  isMuted := false;

  seekerState.value := 0;

  repeatState.checked := true;
  lastRepeat := repeatState.checked;

  volumeState.value := 25;
  lastVolume := volumeState.value;
  SetMusicVolume(volumeState.value / 100.0)
end;


function GetMusicTimeStr: string;
var
  m, s: integer;
begin
  m := trunc(getMusicTime) div 60;
  s := trunc(getMusicTime) mod 60;
  GetMusicTimeStr := i32str(m) + ':' + padStart(i32str(s), 2, '0');
end;


procedure Update;
begin
  UpdateDeltaTime;

  UpdateGUILastMouseButton;
  UpdateMouse;
  UpdateGUIMousePoint;

  { Your Update logic here }
  if lastEsc <> IsKeyDown(SC_ESCAPE) then begin
    lastEsc := IsKeyDown(SC_ESCAPE);
    if lastEsc then SignalDone;
  end;

  gameTime := gameTime + DeltaTime;

  if lastRepeat <> repeatState.checked then begin
    lastRepeat := repeatState.checked;
    SetMusicRepeat(repeatState.checked)
  end;

  if lastVolume <> volumeState.value then begin
    lastVolume := volumeState.value;
    SetMusicVolume(volumeState.value / 100.0)
  end;

  HandleMusicRepeat(BgmClassic);

  ResetWidgetIndices
end;

procedure Draw;
var
  isPlaying: boolean;

  duration, actualTime, seekTime: double;
  dragState: TSliderDragState;
begin
  Cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    Spr(imgDosuEXE[1], 148, 48)
  else
    Spr(imgDosuEXE[0], 148, 48);

  Checkbox('Repeat', 50, 125, repeatState);

  isPlaying := getMusicPlaying;
  if isPlaying then
    PrintDefault('Playing', 10, 10)
  else
    PrintDefault('Paused / Stopped', 10, 10);

  { Music Seeker }
  duration := getMusicDuration;
  actualTime := getMusicTime;

  dragState := SliderDrag(64, 94, 192, seekerState, 0, 100);

  if dragState = SliderReleased then begin
    { writeLog('Attempting to release slider'); }
    seekTime := seekerState.value / 100.0 * duration;
    { writeLogF32(seekTime); }

    SeekMusic(seekTime)
  end;

  if (dragState <> SliderDragging) and (duration > 0.0) then
    seekerState.value := round(actualTime / duration * 100.0);

  { Music time }
  PrintDefault(GetMusicTimeStr, 100, 124);

  { Play / pause button }
  if isPlaying then begin
    if ImageButton(129, 116, imgPause, imgPause, imgPause) then
      pauseMusic;
  end else
    if ImageButton(129, 116, imgPlay, imgPlay, imgPlay) then begin
      if actualMusicKey < 0 then begin
        { Starting new }
        actualMusicKey := BgmClassic;
        PlayMusic(BgmClassic)
      end else
        { Resuming }
        PlayMusic(actualMusicKey);
    end;
  
  if ImageButton(161, 116, imgStop, imgStop, imgStop) then
    StopMusic;

  { Volume control }
  if isMuted or (volumeState.value = 0) then
    spr(imgVolumeOff, 202, 123)
  else
    spr(imgVolumeOn, 202, 123);

  Slider(217, 125, 64, volumeState, 0, 100);

  ResetActiveWidget;

  DrawMouse;

  VgaUpload;
  VgaPresent
end;

exports
  OnPreload, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

