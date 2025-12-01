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

  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      playSound: this.#playSound.bind(this),
      setSoundVolume: this.#setSoundVolume.bind(this),

      playMusic: this.#playMusic.bind(this),
      pauseMusic: this.#pauseMusic.bind(this),
      stopMusic: this.#stopMusic.bind(this),
      seekMusic: this.#seekMusic.bind(this),
      getMusicTime: this.#getMusicTime.bind(this),
      getMusicDuration: this.#getMusicDuration.bind(this),

      getMusicPlaying: () => this.#musicPlaying,
      getMusicRepeat: this.#getMusicRepeat.bind(this),
      setMusicRepeat: this.#setMusicRepeat.bind(this),
      setMusicVolume: this.#setMusicVolume.bind(this),
    })
  }

  /**
   * @override
   */
  async init() {
    this.#initAudio();

    this.#setupImportObject();
    await super.init()
  }

  /**
   * @override
   */
  cleanup() {
    this.#stopMusic();
    super.cleanup()
  }

  #assertNumber(value) {
    if (typeof value != "number")
      throw new Error(`Expected a number, but received ${typeof value}`);

    if (isNaN(value))
      throw new Error("Expected a number, but received NaN");
  }

  #initAudio() {
    this.#audioContext = new AudioContext();
  }


  // SOUNDS.PAS
  async loadSound(key, url) {
    const response = await fetch(url);
    const arrayBuffer = await response.arrayBuffer();
    const audioBuffer = await this.#audioContext.decodeAudioData(arrayBuffer);

    this.#sounds.set(key, audioBuffer);
    this.#setSoundVolume(key, 0.5)
  }

  #playSound(key) {
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
  #resetMusicPlayerNode() {
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

  #destroyMusicPlayerNode() {
    if (this.#musicPlayer != null) {
      this.#musicPlayer.stop();
      this.#musicPlayer = null;
      this.#musicGainNode = null;
    }
  }

  #playMusic(key) {
    // If still playing
    if (this.#musicPlaying && this.#musicBuffer != null)
      return;

    // Resuming
    if (this.#musicBuffer != null) {
      this.#resetMusicPlayerNode();
      this.#resumeMusic();
      return
    }

    this.#stopMusic();

    const buffer = this.#sounds.get(key);
    if (buffer == null) {
      console.warn("Music " + key + " is not loaded");
      return
    }

    this.#musicBuffer = buffer;
    this.#musicPauseTime = 0.0;

    this.#resetMusicPlayerNode();
    this.#resumeMusic();
  }

  /**
   * Start playback from a saved position
   * 
   * Requires `#resetMusicPlayerNode()` to be called right before this
   */
  #resumeMusic() {
    this.#musicPlayer.start(0, this.#musicPauseTime);
    this.#musicStartTime = this.#audioContext.currentTime - this.#musicPauseTime;
    this.#musicPlaying = true
  }

  #pauseMusic() {
    if (!this.#musicPlaying || this.#musicPlayer == null)
      return;

    this.#musicPauseTime = this.#audioContext.currentTime - this.#musicStartTime;

    // Handle looping
    if (this.#musicBuffer != null) {
      const duration = this.#musicBuffer.duration;  // in seconds
      this.#musicPauseTime %= duration
    }

    // Stop the music player, but don't "forget" the pause position
    this.#destroyMusicPlayerNode();
    this.#musicPlaying = false
  }

  #stopMusic() {
    this.#destroyMusicPlayerNode();
    this.#musicBuffer = null;
    this.#musicPauseTime = 0.0;
    this.#musicPlaying = false
  }

  /**
   * @param {number} t time in seconds
   */
  #seekMusic(t) {
    this.#assertNumber(t);
    if (this.#musicBuffer == null) return;

    const duration = this.#musicBuffer.duration;
    t = this.#clamp(t, 0.0, duration);

    const wasPlaying = this.#musicPlaying;

    // Stop current playback
    this.#destroyMusicPlayerNode();

    this.#musicPauseTime = t;
    this.#musicPlaying = false;

    if (wasPlaying) {
      this.#resetMusicPlayerNode();
      this.#resumeMusic();
    }
  }

  #clamp(value, min, max) {
    this.#assertNumber(value);
    this.#assertNumber(min);
    this.#assertNumber(max);

    return Math.max(min, Math.min(max, value))
  }

  #getMusicRepeat() { return this.#musicRepeat }
  #setMusicRepeat(value) {
    this.#musicRepeat = value;
  }

  #setSoundVolume(key, volume) {
    const clamped = this.#clamp(volume, 0.0, 1.0);
    this.#soundVolumes.set(key, clamped)
  }

  #setMusicVolume(volume) {
    this.#musicVolume = this.#clamp(volume, 0.0, 1.0);

    if (this.#musicGainNode != null)
      this.#musicGainNode.gain.value = this.#musicVolume;
  }

  #getMusicDuration() {
    if (this.#musicBuffer == null)
      return 0.0;

    return this.#musicBuffer.duration
  }

  #getMusicTime() {
    if (this.#musicBuffer == null)
      return 0.0;

    if (!this.#musicPlaying)
      return this.#musicPauseTime;

    const elapsed = this.#audioContext.currentTime - this.#musicStartTime;
    const duration = this.#getMusicDuration();

    return elapsed % duration
  }
}