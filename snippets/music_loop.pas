{ Step 1: Enable music repeat on afterInit }
setMusicRepeat(true)


{ Step 2: Add this at the end of update routine }

{ Handle music repeat manually (only when it is playing)
  Important: #musicPlayer.loop must be turned off! }
if getMusicPlaying and (getMusicTime >= getMusicDuration - 0.05) then
  if getMusicRepeat then begin
    stopMusic;
    playMusic({ Your BGM key })
  end else
    stopMusic;
