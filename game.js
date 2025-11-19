const white = 0xFFFFFFFF;
const yellow = 0xFFFFFF55;

var done = false;

async function main() {
  const P92 = new Posit92("game");
  await P92.init();

  await P92.loadAssets();

  // Draw only 1 frame

  // P92.update();
  // P92.draw();

  // P92.stressTest();

  // Stress test
  // while (!done) {
  //   P92.update();
  //   P92.draw();
  // }

  function loop() {
    if (done) return;

    P92.update();
    P92.draw();
    requestAnimationFrame(loop)

    // P92.printDefault("Hello from POSIT-92!", 10, 10);
    // P92.spr(imgGasolineMaid, 10, 30);
    // P92.flush();
  }
  loop();


  // Stress test 1
  // P92.startStressTest();

  // Stress test 2
  // P92.startBenchmark();
}

main()
