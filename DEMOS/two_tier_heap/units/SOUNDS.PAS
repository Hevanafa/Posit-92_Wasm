{
  Sounds unit - Part of Posit-92 game engine
  By Hevanafa

  Requires SoundsMixin class
}

unit Sounds;

{$Mode TP}
{$B-}

interface

procedure playSound(const key: longint); external 'env' name 'playSound';

procedure playMusic(const key: longint); external 'env' name 'playMusic';
function getMusicRepeat: boolean; external 'env' name 'getMusicRepeat';
procedure setMusicRepeat(const value: boolean); external 'env' name 'setMusicRepeat';
procedure handleMusicRepeat(const musicKey: integer);
procedure pauseMusic; external 'env' name 'pauseMusic';
procedure stopMusic; external 'env' name 'stopMusic';

{ t: time in seconds }
procedure seekMusic(const t: double); external 'env' name 'seekMusic';
function getMusicPlaying: boolean; external 'env' name 'getMusicPlaying';
function getMusicTime: double; external 'env' name 'getMusicTime';
function getMusicDuration: double; external 'env' name 'getMusicDuration';

procedure setSoundVolume(const key: longint; const volume: double); external 'env' name 'setSoundVolume';
procedure setMusicVolume(const volume: double); external 'env' name 'setMusicVolume';


implementation

{ Handle music repeat (only when it is playing)
  Important: #musicPlayer.loop must be turned off! }
procedure handleMusicRepeat(const musicKey: integer);
begin
  if getMusicPlaying and (getMusicTime >= getMusicDuration - 0.05) then
    if getMusicRepeat then begin
      stopMusic;
      playMusic(musicKey)
    end else
      stopMusic;
end;

end.
