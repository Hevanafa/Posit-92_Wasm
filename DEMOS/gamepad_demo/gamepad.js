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

  #gamepadButton() {}
  #gamepadAxis() {}

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