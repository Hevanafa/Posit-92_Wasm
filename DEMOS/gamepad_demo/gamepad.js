class GamepadMixin extends Posit92 {
  #debug = true;
  #gamepadIndex = -1;

  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      gamepadButton: this.#gamepadButton.bind(this),
      gamepadAxis: this.#gamepadAxis.bind(this)
    })
  }

  #initGamepad() {
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

  /**
   * @param {number} button 
   */
  #gamepadButton(button) {
    if (this.#gamepadIndex < 0) return false;

    const gamepads = navigator.getGamepads();
    const gamepad = gamepads[this.#gamepadIndex];

    if (gamepad == null) return false;

    return gamepad.buttons[button].pressed
  }

  /**
   * @param {number} axis 
   */
  #gamepadAxis(axis) {
    if (this.#gamepadIndex < 0) return false;

    const gamepads = navigator.getGamepads();
    const gamepad = gamepads[this.#gamepadIndex];

    if (gamepad == null) return 0.0;

    return gamepad.axes[axis]
  }

  /**
   * @override
   */
  async init() {
    this.#initGamepad();
    this.#setupImportObject();
    await super.init();
  }

  update() {
    
    super.update()
  }
}