/**
 * Pick either one of these method, paste as a method inside Posit92
 * 
 * Use the method like this in game.js:
 * P92.startStressTest()
 * P92.startBenchmark()
 */

class StressTest {
  #wasm;

  // Stress test 1
  startStressTest() {
    const stressTest = () => {
      const iterations = 100;

      for (let a=0; a<iterations; a++) {
        this.#wasm.exports.update();
        this.#wasm.exports.draw();
      }

      this.flush();

      if (!done) requestAnimationFrame(stressTest)
    }

    stressTest();
  }

  // Stress test 2
  // This doesn't output visually, but outputs directly to the console
  startBenchmark() {
    const start = performance.now();
    for (let a=0; a<10000; a++) {
      this.#wasm.exports.update();
      this.#wasm.exports.draw();
    }

    const elapsed = performance.now() - start;
    console.log(`10000 update & draw calls in ${elapsed}ms = ${10000 / (elapsed / 1000)} FPS`);
  }
}