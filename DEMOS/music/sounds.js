// sounds.ts
class SoundsMixin extends Posit92 {
  #audioContext = null;
  #sounds = new Map;
  #soundVolumes = new Map;
  #musicPlayer = null;
  #musicGainNode = null;
  #musicBuffer = null;
  #musicRepeat = true;
  #musicVolume = 1;
  #musicStartTime = 0;
  #musicPauseTime = 0;
  #musicPlaying = false;
  SetupImportObject() {
    const { env } = this.WasmImportObject;
    Object.assign(env, {
      PlaySound: this.#PlaySound.bind(this),
      SetSoundVolume: this.#SetSoundVolume.bind(this),
      PlayMusic: this.#PlayMusic.bind(this),
      PauseMusic: this.#PauseMusic.bind(this),
      StopMusic: this.#StopMusic.bind(this),
      SeekMusic: this.#SeekMusic.bind(this),
      GetMusicTime: this.#GetMusicTime.bind(this),
      GetMusicDuration: this.#GetMusicDuration.bind(this),
      GetMusicPlaying: () => this.#musicPlaying,
      GetMusicRepeat: this.#GetMusicRepeat.bind(this),
      SetMusicRepeat: this.#SetMusicRepeat.bind(this),
      SetMusicVolume: this.#SetMusicVolume.bind(this)
    });
  }
  async InitRuntime() {
    this.#InitAudio();
    await super.InitRuntime();
  }
  Cleanup() {
    this.#StopMusic();
    super.Cleanup();
  }
  #InitAudio() {
    this.#audioContext = new AudioContext;
  }
  async LoadSound(key, url) {
    const response = await fetch(url);
    const arrayBuffer = await response.arrayBuffer();
    if (this.#audioContext == null)
      throw new Error("LoadSound: audioContext is not initialised!");
    const audioBuffer = await this.#audioContext.decodeAudioData(arrayBuffer);
    console.log("loadSound", key, url);
    this.#sounds.set(key, audioBuffer);
    this.#SetSoundVolume(key, 0.5);
  }
  async LoadSoundsFromManifest(manifest) {
    const entries = Array.from(manifest.entries());
    this.IncLoadingTotal(manifest.size);
    const promises = entries.map(([key, url]) => this.LoadSound(key, url).then(() => {
      return { key, url, success: true };
    }).catch((err) => {
      console.error("Failed to load sound: " + url, err);
      return { key, url, success: false };
    }).finally(() => {
      this.IncLoadingActual();
    }));
    const results = await Promise.all(promises);
    const failures = results.filter((item) => !item.success);
    if (failures.length > 0) {
      console.error("Failed to load sounds:");
      for (const failure of failures)
        console.error("   " + failure.key + ": " + failure.url);
      throw new Error("Failed to load some sounds");
    }
  }
  #PlaySound(key) {
    if (this.#audioContext == null)
      throw new Error("PlaySound: audioContext is not initialised!");
    const buffer = this.#sounds.get(key);
    if (buffer == null) {
      console.warn("PlaySound: Sound " + key + " is not loaded!");
      return;
    }
    const volume = this.#soundVolumes.get(key) ?? 0;
    if (!this.#soundVolumes.has(key))
      console.warn("Missing sound volume for key " + key);
    const source = this.#audioContext.createBufferSource();
    const gainNode = this.#audioContext.createGain();
    source.buffer = buffer;
    gainNode.gain.value = volume;
    source.connect(gainNode);
    gainNode.connect(this.#audioContext.destination);
    source.start(0);
  }
  #ResetMusicPlayerNode() {
    if (this.#audioContext == null)
      throw new Error("ResetMusicPlayerNode: audioContext is not initialised!");
    this.#musicPlayer = this.#audioContext.createBufferSource();
    this.#musicGainNode = this.#audioContext.createGain();
    this.#musicPlayer.buffer = this.#musicBuffer;
    this.#musicGainNode.gain.value = this.#musicVolume;
    this.#musicPlayer.connect(this.#musicGainNode);
    this.#musicGainNode.connect(this.#audioContext.destination);
  }
  #DestroyMusicPlayerNode() {
    if (this.#musicPlayer == null)
      return;
    this.#musicPlayer.stop();
    this.#musicPlayer = null;
    this.#musicGainNode = null;
  }
  #PlayMusic(key) {
    if (this.#musicPlaying && this.#musicBuffer != null)
      return;
    if (this.#musicBuffer != null) {
      this.#ResetMusicPlayerNode();
      this.#ResumeMusic();
      return;
    }
    this.#StopMusic();
    const buffer = this.#sounds.get(key);
    if (buffer == null) {
      console.warn("Music " + key + " is not loaded");
      return;
    }
    this.#musicBuffer = buffer;
    this.#musicPauseTime = 0;
    this.#ResetMusicPlayerNode();
    this.#ResumeMusic();
  }
  #ResumeMusic() {
    if (this.#musicPlayer == null)
      throw new Error("ResumeMusic: musicPlayer is not initialised!");
    if (this.#audioContext == null)
      throw new Error("ResumeMusic: audioContext is not initialised!");
    this.#musicPlayer.start(0, this.#musicPauseTime);
    this.#musicStartTime = this.#audioContext.currentTime - this.#musicPauseTime;
    this.#musicPlaying = true;
  }
  #PauseMusic() {
    if (!this.#musicPlaying || this.#musicPlayer == null)
      return;
    if (this.#audioContext == null)
      throw new Error("PauseMusic: audioContext is not initialised!");
    this.#musicPauseTime = this.#audioContext.currentTime - this.#musicStartTime;
    if (this.#musicBuffer != null) {
      const duration = this.#musicBuffer.duration;
      this.#musicPauseTime %= duration;
    }
    this.#DestroyMusicPlayerNode();
    this.#musicPlaying = false;
  }
  #StopMusic() {
    this.#DestroyMusicPlayerNode();
    this.#musicBuffer = null;
    this.#musicPauseTime = 0;
    this.#musicPlaying = false;
  }
  #SeekMusic(t) {
    this.AssertNumber(t);
    if (this.#musicBuffer == null)
      return;
    const duration = this.#musicBuffer.duration;
    t = this.Clamp(t, 0, duration);
    const wasPlaying = this.#musicPlaying;
    this.#DestroyMusicPlayerNode();
    this.#musicPauseTime = t;
    this.#musicPlaying = false;
    if (wasPlaying) {
      this.#ResetMusicPlayerNode();
      this.#ResumeMusic();
    }
  }
  #GetMusicRepeat() {
    return this.#musicRepeat;
  }
  #SetMusicRepeat(value) {
    this.#musicRepeat = value;
  }
  #SetSoundVolume(key, volume) {
    const clamped = this.Clamp(volume, 0, 1);
    this.#soundVolumes.set(key, clamped);
  }
  #SetMusicVolume(volume) {
    this.#musicVolume = this.Clamp(volume, 0, 1);
    if (this.#musicGainNode != null)
      this.#musicGainNode.gain.value = this.#musicVolume;
  }
  #GetMusicDuration() {
    if (this.#musicBuffer == null)
      return 0;
    return this.#musicBuffer.duration;
  }
  #GetMusicTime() {
    if (this.#audioContext == null)
      throw new Error("GetMusicTime: audioContext is not initialised!");
    if (this.#musicBuffer == null)
      return 0;
    if (!this.#musicPlaying)
      return this.#musicPauseTime;
    const elapsed = this.#audioContext.currentTime - this.#musicStartTime;
    const duration = this.#GetMusicDuration();
    return elapsed % duration;
  }
}
