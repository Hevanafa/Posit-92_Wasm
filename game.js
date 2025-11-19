const white = 0xFFFFFFFF;
const yellow = 0xFFFFFF55;

async function main() {
  const P92 = new Posit92("game");
  await P92.init();

  // Load assets
  // const imgSatono = await P92.loadImage("assets/images/satono_diamond.png");
  // const imgDefaultFont = await P92.loadImage("assets/fonts/nokia_cellphone_fc_8_0.png")
  const imgGasolineMaid = await P92.loadImage("assets/images/gasoline_maid_100px.png")

  await P92.loadBMFont("assets/fonts/nokia_cellphone_fc_8.txt");

  let done = false;
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
}

main()
