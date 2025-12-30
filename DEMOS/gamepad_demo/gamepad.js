class GamepadMixin extends Posit92 {
  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      gamepadButton: this.#gamepadButton.bind(this),
      gamepadAxis: this.#gamepadAxis.bind(this)
    })
  }

  #initGamepad() {
    window.addEventListener("gamepadconnected", e => {
      console.log("Gamepad connected:", e.gamepad);
    });

    window.addEventListener("gamepaddisconnected", e => {
      console.log("Gamepad disconnected:", e.gamepad);
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