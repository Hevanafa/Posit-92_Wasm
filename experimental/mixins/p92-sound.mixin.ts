/**
 * Sounds mixin
 * 
 * Part of Posit-92 game engine
 */

type SoundWasmExports = WasmExports & {
  // AssetRegistry
  PascalSoundLoaded: (sndHandle: number) => void,
  PascalSoundFailed: (sndHandle: number) => void,

  // Sounds
  GetSoundVolume: (sndHandle: number) => number;
  SetSoundVolume: (sndHandle: number, volume: number) => void;

  GetMusicPlaying: () => boolean,
  GetMusicVolume: () => number
}

globalThis.SoundMixin = <T extends Constructor<Posit92>>(Base: T) =>
class SoundMixin extends Base {
  #audioContext: AudioContext | null = null;

  #sounds: Map<number, AudioBuffer> = new Map();

  /**
   * One-shot, dies after `.stop()`
   */
  #musicPlayer: AudioBufferSourceNode | null = null;

  /**
   * One-shot, dies after `.stop()`
   */
  #musicGainNode: GainNode | null = null;

  /**
   * Reusable audio buffer data
   */
  #musicBuffer: AudioBuffer | null = null;

  SetupImportObject(): void {
    super.SetupImportObject();

    const { env } = this.WasmImportObject;

    Object.assign(env, {
      JsInitAudio: this.#InitAudio.bind(this),
      JsPlaySound: this.#PlaySound.bind(this),

      JsRequestSound: this.#RequestSound.bind(this),

      // PlayMusic: this.#PlayMusic.bind(this),
      JsResetMusicPlayerNode: this.#ResetMusicPlayerNode.bind(this),
      PauseMusic: this.#PauseMusic.bind(this),
      StopMusic: this.#StopMusic.bind(this),
      SeekMusic: this.#SeekMusic.bind(this),
      
      GetMusicTime: this.#GetMusicTime.bind(this),
      GetMusicDuration: this.#GetMusicDuration.bind(this),

      JsSetMusicVolume: this.#SetMusicVolume.bind(this),
    });
  }

  get WasmInstanceExports(): SoundWasmExports {
    return <SoundWasmExports> this.WasmInstance.exports;
  }

  /**
   * @override
   */
  Cleanup(): void {
    this.#StopMusic();
    super.Cleanup();
  }

  #InitAudio(): void {
    this.#audioContext = new AudioContext();
  }


  // SOUNDS.PAS

  async #RequestSound(sndHandle: number): Promise<void> {
    const url = this.ReadInteropBuffer();

    console.log("RequestSound", sndHandle, url);

    try {
      const response = await fetch(url);
      const arrayBuffer = await response.arrayBuffer();

      if (this.#audioContext == null)
        throw new Error("LoadSound: audioContext is not initialised!");

      const audioBuffer = await this.#audioContext.decodeAudioData(arrayBuffer);

      this.#sounds.set(sndHandle, audioBuffer);
      this.WasmInstanceExports.SetSoundVolume(sndHandle, 0.5);

      this.WasmInstanceExports.PascalSoundLoaded(sndHandle);
    } catch (error) {
      console.error("RequestSound failed", error);

      const lines = [
        "Failed to load sound",
        "",
        "Path: " + url
      ];

      if (error instanceof Error)
        lines.push("Reason: " + error.message);
      else
        lines.push("Reason: " + error);

      this.PanicHaltDisplay(lines.join("\n"));

      this.WasmInstanceExports.PascalSoundFailed(sndHandle);
    }
  }

  #PlaySound(sndHandle: number): void {
    if (this.#audioContext == null)
      throw new Error("PlaySound: audioContext is not initialised!");

    const buffer = this.#sounds.get(sndHandle);

    if (buffer == null) {
      console.warn("PlaySound: Sound " + sndHandle + " is not loaded!");
      return;
    }

    const volume = this.WasmInstanceExports.GetSoundVolume(sndHandle);
    const source = this.#audioContext.createBufferSource();
    const gainNode = this.#audioContext.createGain();

    source.buffer = buffer;
    gainNode.gain.value = volume;

    // Connect source -> gain -> destination
    source.connect(gainNode);
    gainNode.connect(this.#audioContext.destination);
    source.start(0);
    // source automatically disconnects when done
  }

  /**
   * Create a new music player node
   */
  #ResetMusicPlayerNode(): void {
    if (this.#audioContext == null)
      throw new Error("ResetMusicPlayerNode: audioContext is not initialised!");

    this.#musicPlayer = this.#audioContext.createBufferSource();
    this.#musicGainNode = this.#audioContext.createGain();

    this.#musicPlayer.buffer = this.#musicBuffer;
    // this.#musicPlayer.loop = this.#musicRepeat;
    // console.log("loop?", this.#musicPlayer.loop);
    this.#musicGainNode.gain.value = this.WasmInstanceExports.GetMusicVolume();

    // Connect the audio graph:
    // music player -> gain -> destination
    this.#musicPlayer.connect(this.#musicGainNode);
    this.#musicGainNode.connect(this.#audioContext.destination);
  }

  #DestroyMusicPlayerNode(): void {
    if (this.#musicPlayer == null) return;

    this.#musicPlayer.stop();
    this.#musicPlayer = null;
    this.#musicGainNode = null;
  }

  // #PlayMusic(key: number): void {
  //   // If still playing
  //   if (this.#musicBuffer != null && this.WasmInstanceExports.GetMusicPlaying())
  //     return;

  //   // Resuming
  //   if (this.#musicBuffer != null) {
  //     this.#ResetMusicPlayerNode();
  //     this.#ResumeMusic();
  //     return;
  //   }

  //   this.#StopMusic();

  //   const buffer = this.#sounds.get(key);
  //   if (buffer == null) {
  //     console.warn("Music " + key + " is not loaded");
  //     return;
  //   }

  //   this.#musicBuffer = buffer;
  //   this.#musicPauseTime = 0.0;

  //   this.#ResetMusicPlayerNode();
  //   this.#ResumeMusic();
  // }

  /**
   * Start playback from a saved position
   * 
   * Requires `#resetMusicPlayerNode()` to be called right before this
   */
  #ResumeMusic(): void {
    if (this.#musicPlayer == null)
      throw new Error("ResumeMusic: musicPlayer is not initialised!");

    if (this.#audioContext == null)
      throw new Error("ResumeMusic: audioContext is not initialised!");

    this.#musicPlayer.start(0, this.#musicPauseTime);
    this.#musicStartTime = this.#audioContext.currentTime - this.#musicPauseTime;
    this.#musicPlaying = true;
  }


  #PauseMusic(): void {
    if (!this.#musicPlaying || this.#musicPlayer == null)
      return;

    if (this.#audioContext == null)
      throw new Error("PauseMusic: audioContext is not initialised!");

    this.#musicPauseTime = this.#audioContext.currentTime - this.#musicStartTime;

    // Handle looping
    if (this.#musicBuffer != null) {
      const duration = this.#musicBuffer.duration;  // in seconds
      this.#musicPauseTime %= duration;
    }

    // Stop the music player, but don't "forget" the pause position
    this.#DestroyMusicPlayerNode();
    this.#musicPlaying = false;
  }

  #StopMusic(): void {
    this.#DestroyMusicPlayerNode();
    this.#musicBuffer = null;
    this.#musicPauseTime = 0.0;
    this.#musicPlaying = false;
  }

  /**
   * @param t time in seconds
   */
  #SeekMusic(t: number): void {
    this.AssertNumber(t);
    if (this.#musicBuffer == null) return;

    const duration = this.#musicBuffer.duration;
    t = this.Clamp(t, 0.0, duration);

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

  /**
   * @param volume 0.0 .. 1.0
   */
  #SetMusicVolume(volume: number): void {
    if (this.#musicGainNode != null)
      this.#musicGainNode.gain.value = volume;
  }

  #GetMusicDuration(): number {
    if (this.#musicBuffer == null)
      return 0.0;

    return this.#musicBuffer.duration;
  }

  #GetMusicTime(): number {
    if (this.#audioContext == null)
      throw new Error("GetMusicTime: audioContext is not initialised!");

    if (this.#musicBuffer == null)
      return 0.0;

    if (!this.#musicPlaying)
      return this.#musicPauseTime;

    const elapsed = this.#audioContext.currentTime - this.#musicStartTime;
    const duration = this.#GetMusicDuration();

    return elapsed % duration;
  }
}