/**
 * Sounds mixin
 */
class SoundsMixin extends Posit92 {
  /**
   * @type {AudioContext}
   */
  #audioContext = null;

  /**
   * @type {Map<number, AudioBuffer>}
   */
  #sounds = new Map();
  /**
   * @type {Map<number, number>}
   */
  #soundVolumes = new Map();

  /**
   * @type {AudioBufferSourceNode} One-shot, dies after `.stop()`
   */
  #musicPlayer = null;
  /**
   * @type {GainNode} One-shot, dies after `.stop()`
   */
  #musicGainNode = null;

  /**
   * @type {AudioBuffer} Reusable audio buffer data
   */
  #musicBuffer = null;

  #musicRepeat = true;
  #musicVolume = 1.0;

  /**
   * in seconds
   */
  #musicStartTime = 0.0;
  /**
   * in seconds
   */
  #musicPauseTime = 0.0;
  #musicPlaying = false;

  #SetupImportObject() {
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
      SetMusicVolume: this.#SetMusicVolume.bind(this),
    })
  }

  /**
   * @override
   */
  async Init() {
    this.#InitAudio();
    this.#SetupImportObject();
    await super.Init()
  }

  /**
   * @override
   */
  Cleanup() {
    this.#StopMusic();
    super.Cleanup()
  }

  #AssertNumber(value) {
    if (typeof value != "number")
      throw new Error(`Expected a number, but received ${typeof value}`);

    if (isNaN(value))
      throw new Error("Expected a number, but received NaN");
  }

  #InitAudio() {
    this.#audioContext = new AudioContext();
  }


  // SOUNDS.PAS
  async LoadSound(key, url) {
    const response = await fetch(url);
    const arrayBuffer = await response.arrayBuffer();
    const audioBuffer = await this.#audioContext.decodeAudioData(arrayBuffer);

    console.log("loadSound", key, url);

    this.#sounds.set(key, audioBuffer);
    this.#SetSoundVolume(key, 0.5)
  }

  /**
   * Load sound files from manifest in parallel
   * @param {Map<number, string>} manifest - Key-value pairs of `"asset_key": "sound_path"`
   */
  async LoadSoundsFromManifest(manifest) {
    const entries = Array.from(manifest.entries());

    this.IncLoadingTotal(manifest.size);

    const promises = entries.map(([key, url]) =>
      this.LoadSound(key, url)
        .then(() => {
          // On success
          return { key, url, success: true }
        })
        .catch(err => {
          console.error("Failed to load sound: " + url, err);
          return { key, url, success: false }
        })
        .finally(() => { this.incLoadingActual() })
    );

    const results = await Promise.all(promises);

    // Error handling
    const failures = results.filter(item => !item.success);
    if (failures.length > 0) {
      console.error("Failed to load sounds:");
      
      for (const failure of failures)
        console.error("   " + failure.key + ": " + failure.path);

      throw new Error("Failed to load some sounds")
    }
  }

  #PlaySound(key) {
    const buffer = this.#sounds.get(key);
    if (buffer == null) {
      console.warn("Sound " + key + " is not loaded");
      return
    }

    const volume = this.#soundVolumes.get(key);

    const source = this.#audioContext.createBufferSource();
    const gainNode = this.#audioContext.createGain();

    source.buffer = buffer;
    gainNode.gain.value = volume;

    // Connect source -> gain -> destination
    source.connect(gainNode);
    gainNode.connect(this.#audioContext.destination);
    source.start(0)
    // source automatically disconnects when done
  }

  /**
   * Create a new music player node
   */
  #ResetMusicPlayerNode() {
    this.#musicPlayer = this.#audioContext.createBufferSource();
    this.#musicGainNode = this.#audioContext.createGain();

    this.#musicPlayer.buffer = this.#musicBuffer;
    // this.#musicPlayer.loop = this.#musicRepeat;
    // console.log("loop?", this.#musicPlayer.loop);
    this.#musicGainNode.gain.value = this.#musicVolume;

    // Connect the audio graph:
    // music player -> gain -> destination
    this.#musicPlayer.connect(this.#musicGainNode);
    this.#musicGainNode.connect(this.#audioContext.destination);
  }

  #DestroyMusicPlayerNode() {
    if (this.#musicPlayer != null) {
      this.#musicPlayer.stop();
      this.#musicPlayer = null;
      this.#musicGainNode = null;
    }
  }

  #PlayMusic(key) {
    // If still playing
    if (this.#musicPlaying && this.#musicBuffer != null)
      return;

    // Resuming
    if (this.#musicBuffer != null) {
      this.#ResetMusicPlayerNode();
      this.#ResumeMusic();
      return
    }

    this.#StopMusic();

    const buffer = this.#sounds.get(key);
    if (buffer == null) {
      console.warn("Music " + key + " is not loaded");
      return
    }

    this.#musicBuffer = buffer;
    this.#musicPauseTime = 0.0;

    this.#ResetMusicPlayerNode();
    this.#ResumeMusic();
  }

  /**
   * Start playback from a saved position
   * 
   * Requires `#resetMusicPlayerNode()` to be called right before this
   */
  #ResumeMusic() {
    this.#musicPlayer.start(0, this.#musicPauseTime);
    this.#musicStartTime = this.#audioContext.currentTime - this.#musicPauseTime;
    this.#musicPlaying = true
  }

  #PauseMusic() {
    if (!this.#musicPlaying || this.#musicPlayer == null)
      return;

    this.#musicPauseTime = this.#audioContext.currentTime - this.#musicStartTime;

    // Handle looping
    if (this.#musicBuffer != null) {
      const duration = this.#musicBuffer.duration;  // in seconds
      this.#musicPauseTime %= duration
    }

    // Stop the music player, but don't "forget" the pause position
    this.#DestroyMusicPlayerNode();
    this.#musicPlaying = false
  }

  #StopMusic() {
    this.#DestroyMusicPlayerNode();
    this.#musicBuffer = null;
    this.#musicPauseTime = 0.0;
    this.#musicPlaying = false
  }

  /**
   * @param {number} t time in seconds
   */
  #SeekMusic(t) {
    this.#AssertNumber(t);
    if (this.#musicBuffer == null) return;

    const duration = this.#musicBuffer.duration;
    t = this.#Clamp(t, 0.0, duration);

    const wasPlaying = this.#musicPlaying;

    // Stop current playback
    this.#DestroyMusicPlayerNode();

    this.#musicPauseTime = t;
    this.#musicPlaying = false;

    if (wasPlaying) {
      this.#ResetMusicPlayerNode();
      this.#ResumeMusic();
    }
  }

  #Clamp(value, min, max) {
    this.#AssertNumber(value);
    this.#AssertNumber(min);
    this.#AssertNumber(max);

    return Math.max(min, Math.min(max, value))
  }

  #GetMusicRepeat() { return this.#musicRepeat }
  #SetMusicRepeat(value) {
    this.#musicRepeat = value;
  }

  #SetSoundVolume(key, volume) {
    const clamped = this.#Clamp(volume, 0.0, 1.0);
    this.#soundVolumes.set(key, clamped)
  }

  #SetMusicVolume(volume) {
    this.#musicVolume = this.#Clamp(volume, 0.0, 1.0);

    if (this.#musicGainNode != null)
      this.#musicGainNode.gain.value = this.#musicVolume;
  }

  #GetMusicDuration() {
    if (this.#musicBuffer == null)
      return 0.0;

    return this.#musicBuffer.duration
  }

  #GetMusicTime() {
    if (this.#musicBuffer == null)
      return 0.0;

    if (!this.#musicPlaying)
      return this.#musicPauseTime;

    const elapsed = this.#audioContext.currentTime - this.#musicStartTime;
    const duration = this.#GetMusicDuration();

    return elapsed % duration
  }
}