"use strict";

var done = false;

async function main() {
  const P92 = new Posit92("game");
  await P92.init();
  await P92.loadAssets();
  P92.afterInit();

  function loop() {
    if (done) {
      P92.cleanup();
      return;
    }

    P92.update();
    P92.draw();
    requestAnimationFrame(loop)
  }
  loop();
}

function play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)

  main()
}

// main()
