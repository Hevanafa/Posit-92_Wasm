class BigIntMixin extends Posit92 {
  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      // TODO: BigInt method binds here
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