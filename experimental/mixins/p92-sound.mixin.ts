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

  GetMusicPlaying: () => boolean;
  SetMusicPlaying: (value: boolean) => void;

  GetMusicStartTime: () => number;
  SetMusicStartTime: (value: number) => void;
  GetMusicPauseTime: () => number;
  SetMusicPauseTime: (value: number) => number;

  GetMusicVolume: () => number
  SetMusicVolume: (value: number) => void;
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
   * Reusable audio buffer data, cleared on `StopMusic()`
   */
  #musicBuffer: AudioBuffer | null = null;

  SetupImportObject(): void {
    super.SetupImportObject();

    const { env } = this.WasmImportObject;

    Object.assign(env, {
      // AssetRegistry
      JsRequestSound: this.#RequestSound.bind(this),

      // Sounds
      JsInitAudio: this.#InitAudio.bind(this),
      
      JsPlaySound: this.#PlaySound.bind(this),

      // PlayMusic: this.#PlayMusic.bind(this),
      JsLoadMusicBuffer: this.#LoadMusicBuffer.bind(this),
      JsResetMusicPlayerNode: this.#ResetMusicPlayerNode.bind(this),
      
      JsResumeMusic: this.#ResumeMusic.bind(this),
      JsPauseMusic: this.#PauseMusic.bind(this),
      JsStopMusic: this.#StopMusic.bind(this),
      JsSeekMusic: this.#SeekMusic.bind(this),
      
      JsGetMusicTime: this.#GetMusicTime.bind(this),
      JsGetMusicDuration: this.#GetMusicDuration.bind(this),

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

  #LoadMusicBuffer(sndHandle: number): void {
    if (!this.#sounds.has(sndHandle))
      throw new Error("Missing sndHandle " + sndHandle);

    this.#musicBuffer = this.#sounds.get(sndHandle)!
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
    // Handle loop manually
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
   * Requires `#ResetMusicPlayerNode()` to be called right before this
   */
  #ResumeMusic(): void {
    if (this.#musicPlayer == null)
      throw new Error("ResumeMusic: musicPlayer is not initialised!");

    if (this.#audioContext == null)
      throw new Error("ResumeMusic: audioContext is not initialised!");

    this.#musicPlayer.start(0, this.WasmInstanceExports.GetMusicPauseTime());

    this.WasmInstanceExports.SetMusicStartTime(
      this.#audioContext.currentTime - this.WasmInstanceExports.GetMusicPauseTime());
    this.WasmInstanceExports.SetMusicPlaying(true);
  }


  #PauseMusic(): void {
    if (this.#audioContext == null)
      throw new Error("PauseMusic: audioContext is not initialised!");

    if (this.#musicPlayer == null)
      return;

    // if (!this.#musicPlaying)
    if (!this.WasmInstanceExports.GetMusicPlaying())
      return;

    // this.#musicPauseTime = this.#audioContext.currentTime - this.#musicStartTime;
    this.WasmInstanceExports.SetMusicPauseTime(
      this.#audioContext.currentTime - this.WasmInstanceExports.GetMusicStartTime());

    // Handle looping
    if (this.#musicBuffer != null) {
      const duration = this.#musicBuffer.duration;  // in seconds
      
      // this.#musicPauseTime %= duration;
      this.WasmInstanceExports.SetMusicPauseTime(
        this.WasmInstanceExports.GetMusicPauseTime() % duration); // float modulo
    }

    // Stop the music player, but don't "forget" the pause position
    this.#DestroyMusicPlayerNode();
    // this.#musicPlaying = false;
    this.WasmInstanceExports.SetMusicPlaying(false);
  }

  #StopMusic(): void {
    this.#DestroyMusicPlayerNode();
    this.#musicBuffer = null;

    // this.#musicPauseTime = 0.0;
    // this.#musicPlaying = false;
    this.WasmInstanceExports.SetMusicPauseTime(0.0);
    this.WasmInstanceExports.SetMusicPlaying(false);
  }

  /**
   * @param t time in seconds
   */
  #SeekMusic(t: number): void {
    if (this.#musicBuffer == null) return;

    const duration = this.#musicBuffer.duration;
    t = this.Clamp(t, 0.0, duration);

    // const wasPlaying = this.#musicPlaying;
    const wasPlaying = this.WasmInstanceExports.GetMusicPlaying();

    // Stop current playback
    this.#DestroyMusicPlayerNode();

    // this.#musicPlaying = false;
    // this.#musicPauseTime = t;

    this.WasmInstanceExports.SetMusicPlaying(false);
    this.WasmInstanceExports.SetMusicPauseTime(t);

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

    if (!this.WasmInstanceExports.GetMusicPlaying())
      return this.WasmInstanceExports.GetMusicPauseTime();

    const elapsed = this.#audioContext.currentTime - this.WasmInstanceExports.GetMusicStartTime();
    const duration = this.#GetMusicDuration();

    return elapsed % duration;
  }
}