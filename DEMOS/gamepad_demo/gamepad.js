class GamepadMixin extends Posit92 {
  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      gamepadButton: this.#gamepadButton.bind(this),
      gamepadAxis: this.#gamepadAxis.bind(this)
    })
  }

  #gamepadButton() {}
  #gamepadAxis() {}

  /**
   * @override
   */
  async init() {
    this.#setupImportObject();
    await super.init();
  }

  update() {
    
    super.update()
  }
}