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

procedure PlaySound(const key: longint); external 'env' name 'PlaySound';

procedure PlayMusic(const key: longint); external 'env' name 'PlayMusic';
function GetMusicRepeat: boolean; external 'env' name 'GetMusicRepeat';
procedure SetMusicRepeat(const value: boolean); external 'env' name 'SetMusicRepeat';
procedure HandleMusicRepeat(const musicKey: smallint);
procedure PauseMusic; external 'env' name 'PauseMusic';
procedure StopMusic; external 'env' name 'StopMusic';

{ t: time in seconds }
procedure SeekMusic(const t: double); external 'env' name 'SeekMusic';
function GetMusicPlaying: boolean; external 'env' name 'GetMusicPlaying';
function GetMusicTime: double; external 'env' name 'GetMusicTime';
function GetMusicDuration: double; external 'env' name 'GetMusicDuration';

procedure SetSoundVolume(sndHandle: longint; volume: double); public name 'SetSoundVolume';
procedure SetMusicVolume(const volume: double); external 'env' name 'SetMusicVolume';


implementation

uses P92Maths;

var
  soundVolumes: array[1..255] of double;

procedure InitSounds;
var
  a: word;
begin
  for a:=1 to high(soundVolumes) do
    soundVolumes[a] := 0.0;
end;

procedure SetSoundVolume(sndHandle: longint; volume: double);
begin
  volume := clamp(volume, 0.0, 1.0);
  soundVolumes[sndHandle] := volume
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
