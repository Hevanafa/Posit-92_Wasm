const white = 0xFFFFFFFF;
const yellow = 0xFFFFFF55;

async function main() {
  const P92 = new Posit92("game");
  await P92.init();

  // Begin render logic
  P92.cls(0xFF6495ED);

  // Load assets
  const imgSatono = await P92.loadImage("assets/images/satono_diamond.png");
  const imgDefaultFont = await P92.loadImage("assets/fonts/nokia_cellphone_fc_8_0.png")
  const imgGasolineMaid = await P92.loadImage("assets/images/gasoline_maid.png")

  console.log("imgSatono handle:", imgSatono);
  console.log("imgDefaultFont handle:", imgDefaultFont);

  // P92.debugImage(imgSatono);
  P92.debugImage(imgDefaultFont);
  
  P92.spr(imgGasolineMaid, 0, 0);

  // P92.spr(imgSatono, 50, 10);
  // P92.sprRegion(imgSatono, 0, 0, 10, 10, 30, 10);
  // P92.sprRegion(imgDefaultFont, 0, 0, 10, 10, 30, 30);

  P92.circ(10, 10, 5, white);
  P92.circfill(10, 30, 5, yellow);

  P92.rect(50, 10, 150, 98, white);
  P92.rectfill(160, 10, 260, 98, yellow);

  P92.line(50, 10, 150, 98, yellow);

  P92.flush();
}

main()
