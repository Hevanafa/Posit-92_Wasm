// Copy either one of these to the main() function in game.js

/*
 * Loop 1 (default)
 */
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


/*
 * Loop 2 (with frame limiter)
 */

// Add these variables at the top
const TargetFPS = 60;
const FrameTime = 1000 / 60.0;
/**
 * in milliseconds
 */
let lastFrameTime = 0.0;

// Add this in main() function
function loop(currentTime) {
  if (done) {
    P92.cleanup();
    return;
  }

  const elapsed = currentTime - lastFrameTime;

  if (elapsed >= FrameTime) {
    lastFrameTime = currentTime;
    P92.update();
    P92.draw();
  }

  requestAnimationFrame(loop)
}

requestAnimationFrame(loop)
