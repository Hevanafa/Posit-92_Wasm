{ Step 1: Enable music repeat on afterInit }
setMusicRepeat(true);


{ Step 2: Add this at the end of update routine }

{ Handle music repeat manually (only when it is playing)
  Important: #musicPlayer.loop must be turned off! }
handleMusicRepeat({ Your BGM key });

{ Alt version with a state variable: }
handleMusicRepeat(actualMusicKey);
