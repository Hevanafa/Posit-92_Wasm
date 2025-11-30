class Sounds extends Posit92 {
  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      // TODO: Move sound methods here
    })
  }

  /**
   * @override
   */
  async init() {
    this.#setupImportObject();
    await super.init()
  }
}