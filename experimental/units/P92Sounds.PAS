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

procedure PlayMusic(const sndHandle: longint);
procedure ResumeMusic;
procedure PauseMusic; external 'env' name 'PauseMusic';
procedure StopMusic; external 'env' name 'StopMusic';

function GetMusicVolume: double; public name 'GetMusicVolume';
procedure SetMusicVolume(value: double); public name 'SetMusicVolume';
procedure JsSetMusicVolume(volume: double); external 'env' name 'JsSetMusicVolume';

function GetMusicPlaying: boolean; public name 'GetMusicPlaying';
procedure SetMusicPlaying(value: boolean); public name 'SetMusicPlaying';

function GetMusicStartTime: double; public name 'GetMusicStartTime';
procedure SetMusicStartTime(value: double); public name 'SetMusicStartTime';

function GetMusicPauseTime: double; public name 'GetMusicPauseTime';
procedure SetMusicPauseTime(value: double); public name 'SetMusicPauseTime';

{ t: time in seconds }
procedure SeekMusic(const t: double); external 'env' name 'SeekMusic';

function GetMusicTime: double; external 'env' name 'GetMusicTime';
function GetMusicDuration: double; external 'env' name 'GetMusicDuration';

function GetMusicRepeat: boolean; public name 'GetMusicRepeat';
procedure SetMusicRepeat(const value: boolean); public name 'SetMusicRepeat';
procedure HandleMusicRepeat(const musicKey: smallint);


implementation

uses
  P92AssetRegistry, P92Conversions, P92Maths, P92PanicDisplay;

var
  soundVolumes: array[1..255] of double;

  musicBufferHandle: longint;
  musicPlaying: boolean;
  musicRepeat: boolean;
  musicVolume: double;
  { in seconds }
  musicStartTime, musicPauseTime: double;

{ initialises the main audio context }
procedure JsInitAudio; external 'env' name 'JsInitAudio';
procedure JsPlaySound(sndHandle: longint); external 'env' name 'JsPlaySound';

procedure JsAssignMusicBuffer(sndHandle: longint); external 'env' name 'JsAssignMusicBuffer';
procedure JsPlayMusic; external 'env' name 'JsPlayMusic';
procedure JsResetMusicPlayerNode; external 'env' name 'JsResetMusicPlayerNode';

procedure InitSounds;
var
  a: word;
begin
  for a:=1 to high(soundVolumes) do
    soundVolumes[a] := 0.0;

  musicBufferHandle := 0;
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

procedure PlayMusic(const sndHandle: longint);
begin
  if (musicBufferHandle <> 0) and musicPlaying then exit;

  { Resuming }
  if musicBufferHandle <> 0 then begin
    JsResetMusicPlayerNode;
    ResumeMusic;
    exit
  end;

  StopMusic;
  musicBufferHandle := sndHandle;
  JsAssignMusicBuffer(sndHandle);
  musicPauseTime := 0.0;

  JsResetMusicPlayerNode;
  ResumeMusic
end;

procedure ResumeMusic;
begin

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
procedure HandleMusicRepeat(const musicKey: smallint);
begin
  if GetMusicPlaying and (GetMusicTime >= GetMusicDuration - 0.05) then
    if GetMusicRepeat then begin
      StopMusic;
      PlayMusic(musicKey)
    end else
      StopMusic;
end;

end.
