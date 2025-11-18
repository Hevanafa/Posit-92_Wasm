const white = 0xFFFFFFFF;
const yellow = 0xFFFFFF55;

async function main() {
  const P92 = new Posit92("game");
  await P92.init();

  // Load assets
  const imgSatono = await P92.loadImage("assets/images/satono_diamond.png");
  const imgDefaultFont = await P92.loadImage("assets/fonts/nokia_cellphone_fc_8_0.png")
  const imgGasolineMaid = await P92.loadImage("assets/images/gasoline_maid.png")

  await P92.loadBMFont("assets/fonts/nokia_cellphone_fc_8.txt");

  // Begin render logic
  P92.cls(0xFF6495ED);

  console.log("imgSatono handle:", imgSatono);
  console.log("imgDefaultFont handle:", imgDefaultFont);

  // P92.debugImage(imgGasolineMaid);
  // P92.debugImage(imgSatono);
  // P92.debugImage(imgDefaultFont);
  
  P92.spr(imgGasolineMaid, 0, 0);
  P92.spr(imgSatono, 50, 10);
  // P92.sprRegion(imgSatono, 0, 0, 10, 10, 30, 10);
  // P92.sprRegion(imgDefaultFont, 0, 0, 10, 10, 30, 30);

  P92.printBMFont("Hello from POSIT-92!", 10, 10);

  P92.flush();
}

main()
