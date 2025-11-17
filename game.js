async function main() {
  await init();

  // Begin render logic
  cls(0xFF6495ED);

  // Debug surfacePtr
  // const memory = new Uint8Array(wasm.exports.memory.buffer, surfacePtr, 20);
  // console.log("First 20 bytes:", Array.from(memory));

  // wasm.exports.spr(10, 10, img.width, img.height);
  // spr(10, 10, 100, 88);

  // Load assets
  const imgSatono = await loadImage("assets/images/satono_diamond.png");
  console.log("imgSatono handle:", imgSatono);
  // wasm.exports.debugImage(imgSatono);
  spr(imgSatono, 50, 10);

  flush();
}

main()
