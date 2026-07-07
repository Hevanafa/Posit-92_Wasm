{
  Sounds unit
  Part of Posit-92 game engine
  By Hevanafa

  Requires SoundsMixin class
}

unit P92Sounds;

{$Mode ObjFPC}
{$H+}{$J-}

interface

procedure InitSounds;

procedure PlaySound(const sndHandle: longint);

function GetSoundVolume(sndHandle: longint): double; public name 'GetSoundVolume';
procedure SetSoundVolume(sndHandle: longint; volume: double); public name 'SetSoundVolume';

{ Music playback }

procedure PlayMusic(const sndHandle: longint);
procedure SeekMusic(t: double);
procedure PauseMusic;
procedure StopMusic;

function GetMusicTime: double;
function GetMusicDuration: double;

function GetMusicVolume: double; public name 'GetMusicVolume';
procedure SetMusicVolume(value: double); public name 'SetMusicVolume';

function GetMusicPlaying: boolean; public name 'GetMusicPlaying';
procedure SetMusicPlaying(value: boolean); public name 'SetMusicPlaying';

function GetMusicStartTime: double; public name 'GetMusicStartTime';
procedure SetMusicStartTime(value: double); public name 'SetMusicStartTime';

function GetMusicPauseTime: double; public name 'GetMusicPauseTime';
procedure SetMusicPauseTime(value: double); public name 'SetMusicPauseTime';

function GetMusicRepeat: boolean; public name 'GetMusicRepeat';
procedure SetMusicRepeat(const value: boolean); public name 'SetMusicRepeat';
procedure HandleMusicRepeat(const sndHandle: smallint);


implementation

uses
  P92AssetRegistry, P92Conversions, P92Maths, P92PanicDisplay;

var
  soundVolumes: array[1..255] of double;

  currentMusicHandle: longint;
  musicPlaying: boolean;
  musicRepeat: boolean;
  musicVolume: double;
  { in seconds }
  musicStartTime, musicPauseTime: double;

{ initialises the audioContext }
procedure JsInitAudio; external 'env' name 'JsInitAudio';

procedure JsPlaySound(sndHandle: longint); external 'env' name 'JsPlaySound';
procedure JsPauseMusic; external 'env' name 'JsPauseMusic';
procedure JsStopMusic; external 'env' name 'JsStopMusic';

procedure JsSetMusicVolume(volume: double); external 'env' name 'JsSetMusicVolume';

function JsGetMusicTime: double; external 'env' name 'JsGetMusicTime';
function JsGetMusicDuration: double; external 'env' name 'JsGetMusicDuration';

procedure JsPlayMusic; external 'env' name 'JsPlayMusic';
procedure JsResumeMusic; external 'env' name 'JsResumeMusic';
procedure JsResetMusicPlayerNode; external 'env' name 'JsResetMusicPlayerNode';
procedure JsLoadMusicBuffer(sndHandle: longint); external 'env' name 'JsLoadMusicBuffer';

procedure InitSounds;
var
  a: word;
begin
  for a:=1 to high(soundVolumes) do
    soundVolumes[a] := 0.0;

  currentMusicHandle := 0;
  musicPlaying := false;
  musicRepeat := true;
  musicVolume := 1.0;
  musicStartTime := 0.0;
  musicPauseTime := 0.0;

  JsInitAudio
end;

procedure PlaySound(const sndHandle: longint);
begin
  JsPlaySound(sndHandle)
end;

function GetSoundVolume(sndHandle: longint): double;
begin
  if (sndHandle < low(soundVolumes)) or (sndHandle > high(soundVolumes)) then
    PanicHaltDisplay('Invalid sndHandle: ' + I32Str(sndHandle));

  GetSoundVolume := soundVolumes[sndHandle];
end;

procedure SetSoundVolume(sndHandle: longint; volume: double);
begin
  volume := clamp(volume, 0.0, 1.0);
  soundVolumes[sndHandle] := volume
end;

{ Music playback }

procedure PlayMusic(const sndHandle: longint);
begin
  if (currentMusicHandle <> 0) and musicPlaying then exit;

  { Resuming }
  if currentMusicHandle <> 0 then begin
    JsResetMusicPlayerNode;
    JsResumeMusic;
    exit
  end;

  JsStopMusic;

  currentMusicHandle := sndHandle;
  JsLoadMusicBuffer(sndHandle);

  musicPauseTime := 0.0;
  JsResetMusicPlayerNode;
  JsResumeMusic
end;

procedure PauseMusic;
begin
  JsPauseMusic
end;

procedure StopMusic;
begin
  JsStopMusic
end;

function MusicLoaded: boolean;
begin
  MusicLoaded := currentMusicHandle > 0
end;

procedure SeekMusic(t: double);
var
  duration: double;
  wasPlaying: boolean;
begin
  if not MusicLoaded then exit;

  duration := JsGetMusicDuration;
  musicPauseTime := clamp(t, 0.0, duration);
  wasPlaying := musicPlaying;

  JsDestroyMusicPlayerNode;
  musicPlaying := false;

  if wasPlaying then begin
    JsResetMusicPlayerNode;
    JsResumeMusic;
    musicPlaying := true;
  end;
end;

function GetMusicDuration: double;
begin
  GetMusicDuration := JsGetMusicDuration
end;

function GetMusicTime: double;
begin
  GetMusicTime := JsGetMusicTime
end;

function GetMusicPlaying: boolean;
begin
  GetMusicPlaying := musicPlaying
end;

procedure SetMusicPlaying(value: boolean);
begin
  musicPlaying := value
end;

function GetMusicStartTime: double;
begin
  GetMusicStartTime := musicStartTime
end;

procedure SetMusicStartTime(value: double);
begin
  musicStartTime := value
end;

function GetMusicPauseTime: double;
begin
  GetMusicPauseTime := musicPauseTime
end;

procedure SetMusicPauseTime(value: double);
begin
  musicPauseTime := value
end;

function GetMusicVolume: double;
begin
  GetMusicVolume := musicVolume
end;

procedure SetMusicVolume(value: double);
begin
  musicVolume := value;
  JsSetMusicVolume(value)
end;

function GetMusicRepeat: boolean;
begin
  GetMusicRepeat := musicRepeat
end;

procedure SetMusicRepeat(const value: boolean);
begin
  musicRepeat := value
end;

{ Handle music repeat (only when it is playing)
  Important: #musicPlayer.loop must be turned off! }
procedure HandleMusicRepeat(const sndHandle: smallint);
begin
  if GetMusicPlaying and (JsGetMusicTime >= JsGetMusicDuration - 0.05) then
    if GetMusicRepeat then begin
      JsStopMusic;
      PlayMusic(sndHandle)
    end else
      JsStopMusic;
end;

end.
