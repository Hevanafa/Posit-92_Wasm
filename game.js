async function main() {
  const P92 = new Posit92("game");
  await P92.init();

  // Begin render logic
  P92.cls(0xFF6495ED);

  // Debug surfacePtr
  // const memory = new Uint8Array(wasm.exports.memory.buffer, surfacePtr, 20);
  // console.log("First 20 bytes:", Array.from(memory));

  // wasm.exports.spr(10, 10, img.width, img.height);
  // spr(10, 10, 100, 88);

  // Load assets
  const imgSatono = await P92.loadImage("assets/images/satono_diamond.png");
  console.log("imgSatono handle:", imgSatono);
  P92.debugImage(imgSatono);
  P92.spr(imgSatono, 50, 10);

  P92.flush();
}

main()
