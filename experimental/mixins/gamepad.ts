// eslint-disable-next-line @typescript-eslint/no-unused-vars
class GamepadMixin extends Posit92 {
  #debug = true;
  #gamepadIndex = -1;

  SetupImportObject(): void {
    const { env } = super.WasmImportObject;

    Object.assign(env, {
      gamepadConnected: this.#GamepadConnected.bind(this),
      gamepadButton: this.#GamepadButton.bind(this),
      gamepadAxis: this.#gamepadAxis.bind(this)
    });
  }

  #InitGamepad(): void {
    window.addEventListener("gamepadconnected", e => {
      if (this.#debug)
        console.log("Gamepad connected:", e.gamepad);

      if (this.#gamepadIndex < 0) {
        this.#gamepadIndex = e.gamepad.index;

        if (this.#debug)
          console.log("index:", this.#gamepadIndex);
      }
    });

    window.addEventListener("gamepaddisconnected", e => {
      if (this.#debug)
        console.log("Gamepad disconnected:", e.gamepad);

      if (e.gamepad.index == this.#gamepadIndex) {
        this.#gamepadIndex = -1;

        if (this.#debug)
          console.log("Active gamepad disconnected");
      }
    });
  }

  #GamepadConnected(): boolean {
    return this.#gamepadIndex >= 0;
  }

  #GamepadButton(button: number): boolean {
    if (this.#gamepadIndex < 0) return false;

    const gamepads = navigator.getGamepads();
    const gamepad = gamepads[this.#gamepadIndex];

    if (gamepad == null) return false;

    return gamepad.buttons[button].pressed;
  }

  #gamepadAxis(axis: number): number {
    if (this.#gamepadIndex < 0) return 0.0;

    const gamepads = navigator.getGamepads();
    const gamepad = gamepads[this.#gamepadIndex];

    if (gamepad == null) return 0.0;

    return gamepad.axes[axis];
  }

  async InitRuntime(): Promise<void> {
    this.#InitGamepad();
    await super.InitRuntime();
  }
}
