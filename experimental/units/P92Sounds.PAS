{
  Sounds unit
  Part of Posit-92 game engine
  By Hevanafa

  Requires SoundsMixin class
}

unit P92Sounds;

{$Mode ObjFPC}
{$H-}{$J-}

interface

uses P92AssetHandles;

procedure InitSounds;
procedure PlaySound(const sndHandle: TSoundHandle);

{$ifdef P92_WASM}
function GetSoundVolume(const sndHandle: TSoundHandle): single; public name 'GetSoundVolume';
procedure SetSoundVolume(const sndHandle: TSoundHandle; volume: single);

{ Music playback }

procedure PlayMusic(const sndHandle: TSoundHandle);
procedure SeekMusic(t: double);
procedure PauseMusic;
procedure StopMusic;

function GetCurrentMusicHandle: TSoundHandle; public name 'GetCurrentMusicHandle';
function GetMusicTime: double;
function GetMusicDuration: double;

function GetMusicPlaying: boolean; public name 'GetMusicPlaying';
procedure SetMusicPlaying(value: boolean); public name 'SetMusicPlaying';

function GetMusicPauseTime: double; public name 'GetMusicPauseTime';
procedure SetMusicPauseTime(value: double); public name 'SetMusicPauseTime';

function GetMusicRepeat: boolean; public name 'GetMusicRepeat';
procedure SetMusicRepeat(const value: boolean); public name 'SetMusicRepeat';
procedure HandleMusicRepeat(const sndHandle: smallint);
{$endif}
{$ifdef P92_SDL2}
procedure CleanupSounds;

function GetSoundVolume(const sndHandle: TSoundHandle): single;
procedure SetSoundVolume(const sndHandle: TSoundHandle; volume: single);
{$endif}


implementation

{$ifdef P92_WASM}
uses
  P92AssetRegistry, P92Conversions, P92Maths, P92PanicDisplay;
{$endif}
{$ifdef P92_SDL2}
uses
  SysUtils, SDL2_Mixer,
  P92AssetRegistry, P92Conversions, P92Maths, P92Logger, P92PanicDisplay;
{$endif}

var
  soundsInitialised: boolean;
{
  As for music playback, Pascal mainly only needs to know about:
  - music position
  - music duration
  - is the music playing?
}

{ Not yet supported in SDL2 mode }
{$ifdef P92_WASM}
  currentMusicHandle: TSoundHandle;
  isMusicPlaying: boolean;
  musicRepeat: boolean;

  { in seconds }
  musicPauseTime: double;
{$endif}

{$ifdef P92_WASM}
{ initialises the audioContext }
procedure JsInitAudio; external 'env' name 'JsInitAudio';

procedure JsPlaySound(sndHandle: longint); external 'env' name 'JsPlaySound';

procedure JsStartMusicPlayer; external 'env' name 'JsStartMusicPlayer';
procedure JsPauseMusic; external 'env' name 'JsPauseMusic';

procedure JsSetMusicBuffer(sndHandle: longint); external 'env' name 'JsSetMusicBuffer';
procedure JsUnsetMusicBuffer; external 'env' name 'JsUnsetMusicBuffer';

procedure JsCreateMusicPlayer; external 'env' name 'JsCreateMusicPlayer';
procedure JsConnectMusicPlayerGraph; external 'env' name 'JsConnectMusicPlayerGraph';
procedure JsDestroyMusicPlayer; external 'env' name 'JsDestroyMusicPlayer';

procedure JsSetMusicVolume(volume: double); external 'env' name 'JsSetMusicVolume';

function JsGetMusicTime: double; external 'env' name 'JsGetMusicTime';
function JsGetMusicDuration: double; external 'env' name 'JsGetMusicDuration';
{$endif}

procedure InitSounds;
var
  a: word;
begin
{$ifdef P92_WASM}
  soundsInitialised := false;

  for a:=1 to high(sounds) do begin
    sounds[a] := default(TSoundEntry);
    sounds[a].volume := 1.0
  end;

  currentMusicHandle := 0;
  isMusicPlaying := false;
  musicRepeat := true;
  musicPauseTime := 0.0;

  JsInitAudio;
  soundsInitialised := true;
{$endif}
{$ifdef P92_SDL2}
  soundsInitialised := false;
  writeLog('initSounds begin');

  if Mix_OpenAudio(MIX_DEFAULT_FREQUENCY,
    MIX_DEFAULT_FORMAT,
    MIX_DEFAULT_CHANNELS, 2048) < 0 then
  begin
    writeLog('initSounds: Couldn''t initialise SDL_Mixer!');
    exit
  end;

  for a:=1 to high(sounds) do begin
    sounds[a] := default(TSoundEntry);
    sounds[a].volume := 1.0
  end;

  writeLog('initSounds end');
  soundsInitialised := true
{$endif}
end;

procedure PlaySound(const sndHandle: TSoundHandle);
{$ifdef P92_SDL2}
var
  sdlVolume: integer;
{$endif}
begin
  if not soundsInitialised then exit;
  if (sndHandle < 1) or (sndHandle > high(sounds)) then exit;

{$ifdef P92_WASM}
  JsPlaySound(sndHandle)
{$endif}
{$ifdef P92_SDL2}
  if sounds[sndHandle].chunk = nil then begin
    writeWarn('Warning: Attempting to play a nil sound');
    exit
  end;

  sdlVolume := round(sounds[sndHandle].volume * 128);
  Mix_VolumeChunk(sounds[sndHandle].chunk, sdlVolume);

  { -1: any available channel
    0: no looping }
  Mix_PlayChannel(-1, sounds[sndHandle].chunk, 0)
{$endif}
end;

function GetSoundVolume(const sndHandle: TSoundHandle): single;
begin
  GetSoundVolume := 0.0;
  if not soundsInitialised then exit;

  if (sndHandle < low(sounds)) or (sndHandle > high(sounds)) then
    PanicHaltDisplay('Invalid sndHandle: ' + I32Str(sndHandle));

  GetSoundVolume := sounds[sndHandle].volume
end;

procedure SetSoundVolume(const sndHandle: TSoundHandle; volume: single);
begin
  if not soundsInitialised then exit;

  if (sndHandle < low(sounds)) or (sndHandle > high(sounds)) then
    exit;

  sounds[sndHandle].volume := Clamp(volume, 0.0, 1.0);

  if sndHandle = currentMusicHandle then
    JsSetMusicVolume(sounds[sndHandle].volume);
end;

{$ifdef P92_WASM}
{ Music playback }
function IsMusicLoaded: boolean;
begin
  IsMusicLoaded := currentMusicHandle > 0
end;

procedure StartMusicPlayer;
begin
  isMusicPlaying := true;
  JsStartMusicPlayer
end;

procedure PlayMusic(const sndHandle: TSoundHandle);
begin
  if IsMusicLoaded and isMusicPlaying then exit;

  { Resuming }
  if IsMusicLoaded then begin
    JsCreateMusicPlayer;
    JsConnectMusicPlayerGraph;
    StartMusicPlayer;
    exit
  end;

  StopMusic;

  currentMusicHandle := sndHandle;
  JsSetMusicBuffer(sndHandle);

  musicPauseTime := 0.0;
  JsCreateMusicPlayer;
  JsConnectMusicPlayerGraph;
  StartMusicPlayer
end;

procedure PauseMusic;
begin
  { JsGetMusicTime only knows if the music is playing or not }
  musicPauseTime := JsGetMusicTime;
  isMusicPlaying := false;
  JsDestroyMusicPlayer
end;

procedure StopMusic;
begin
  isMusicPlaying := false;
  currentMusicHandle := 0;
  musicPauseTime := 0.0;

  JsDestroyMusicPlayer;
  JsUnsetMusicBuffer;
end;

procedure SeekMusic(t: double);
var
  duration: double;
  wasPlaying: boolean;
begin
  if not IsMusicLoaded then exit;

  duration := JsGetMusicDuration;
  musicPauseTime := clamp(t, 0.0, duration);
  wasPlaying := isMusicPlaying;

  JsDestroyMusicPlayer;
  isMusicPlaying := false;

  if wasPlaying then begin
    JsCreateMusicPlayer;
    JsConnectMusicPlayerGraph;
    StartMusicPlayer
  end;
end;

function GetMusicDuration: double;
begin
  GetMusicDuration := JsGetMusicDuration
end;

function GetCurrentMusicHandle: TSoundHandle;
begin
  GetCurrentMusicHandle := currentMusicHandle
end;

function GetMusicTime: double;
begin
  GetMusicTime := JsGetMusicTime
end;

function GetMusicPlaying: boolean;
begin
  GetMusicPlaying := isMusicPlaying
end;

procedure SetMusicPlaying(value: boolean);
begin
  isMusicPlaying := value
end;

function GetMusicPauseTime: double;
begin
  GetMusicPauseTime := musicPauseTime
end;

procedure SetMusicPauseTime(value: double);
begin
  musicPauseTime := value
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
      StopMusic;
      PlayMusic(sndHandle)
    end else
      StopMusic;
end;
{$endif}

{$ifdef P92_SDL2}
procedure CleanupSounds;
var
  a: longint;
begin
  if not soundsInitialised then exit;

  for a := 1 to high(sounds) do
    if sounds[a].chunk <> nil then
      Mix_FreeChunk(sounds[a].chunk);

  Mix_CloseAudio;
  soundsInitialised := false
end;
{$endif}

end.
