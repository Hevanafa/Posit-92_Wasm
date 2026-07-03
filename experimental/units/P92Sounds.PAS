{
  Sounds unit
  Part of Posit-92 game engine
  By Hevanafa

  Requires SoundsMixin class
}

unit Sounds;

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

procedure SetSoundVolume(const key: longint; const volume: double); external 'env' name 'SetSoundVolume';
procedure SetMusicVolume(const volume: double); external 'env' name 'SetMusicVolume';


implementation

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
