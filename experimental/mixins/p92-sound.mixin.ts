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
      JsResumeMusic: this.#ResumeMusic.bind(this),
      JsPauseMusic: this.#PauseMusic.bind(this),

      JsSetMusicBuffer: this.#SetMusicBuffer.bind(this),
      JsUnsetMusicBuffer: this.#UnsetMusicBuffer.bind(this),
      
      JsCreateMusicPlayer: this.#CreateMusicPlayer.bind(this),
      JsConnectMusicPlayerGraph: this.#ConnectMusicPlayerGraph.bind(this),
      JsDestroyMusicPlayer: this.#DestroyMusicPlayer.bind(this),
      
      JsSetMusicVolume: this.#SetMusicVolume.bind(this),
      
      JsGetMusicTime: this.#GetMusicTime.bind(this),
      JsGetMusicDuration: this.#GetMusicDuration.bind(this)
    });
  }

  get WasmInstanceExports(): SoundWasmExports {
    return <SoundWasmExports> this.WasmInstance.exports;
  }

  #InitAudio(): void {
    this.#audioContext = new AudioContext();
  }

  async #RequestSound(sndHandle: number): Promise<void> {
    const url = this.ReadInteropBuffer();

    console.log("RequestSound", sndHandle, url);

    try {
      if (this.#audioContext == null)
        throw new Error("LoadSound: audioContext is not initialised!");

      const response = await fetch(url);
      const arrayBuffer = await response.arrayBuffer();
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

  #SetMusicBuffer(sndHandle: number): void {
    if (!this.#sounds.has(sndHandle))
      throw new Error("Missing sndHandle " + sndHandle);

    this.#musicBuffer = this.#sounds.get(sndHandle)!
  }

  #UnsetMusicBuffer(): void {
    this.#musicBuffer = null;
  }

  /**
   * Create a new music player node
   */
  #CreateMusicPlayer(): void {
    if (this.#audioContext == null)
      throw new Error("ResetMusicPlayerNode: audioContext is not initialised!");

    this.#musicPlayer = this.#audioContext.createBufferSource();
    this.#musicGainNode = this.#audioContext.createGain();

    // Handle loop manually
    // this.#musicPlayer.loop = this.#musicRepeat;
    // console.log("loop?", this.#musicPlayer.loop);
  }

  #ConnectMusicPlayerGraph() {
    this.#musicPlayer.buffer = this.#musicBuffer;
    this.#musicGainNode.gain.value = this.WasmInstanceExports.GetMusicVolume();

    // Connect the audio graph:
    // music player -> gain -> destination
    this.#musicPlayer.connect(this.#musicGainNode);
    this.#musicGainNode.connect(this.#audioContext.destination);
  }

  #DestroyMusicPlayer(): void {
    if (this.#musicPlayer != null) {
      try {
        this.#musicPlayer.stop();
      } catch {}

      this.#musicPlayer.disconnect();
      this.#musicPlayer = null;
    }

    if (this.#musicGainNode != null) {
      this.#musicGainNode.disconnect();
      this.#musicGainNode = null;
    }
  }

  /**
   * Start playback from a saved position
   * 
   * Requires `#ResetMusicPlayerNode()` to be called right before this
   */
  #ResumeMusic(): void {
    if (this.#audioContext == null)
      throw new Error("ResumeMusic: audioContext is not initialised!");

    if (this.#musicPlayer == null)
      throw new Error("ResumeMusic: musicPlayer is not initialised!");

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
      let musicPauseTime = this.WasmInstanceExports.GetMusicPauseTime();

      while (musicPauseTime >= duration)
        musicPauseTime -= duration;
      
      this.WasmInstanceExports.SetMusicPauseTime(
        musicPauseTime);
    }

    // Stop the music player, but don't "forget" the pause position
    this.#DestroyMusicPlayer();
    // this.#musicPlaying = false;
    this.WasmInstanceExports.SetMusicPlaying(false);
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