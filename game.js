/**
 * @type {HTMLCanvasElement}
 */
const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");

async function main() {

}

// TODO: Upgrade this to an async function
const importObject = {
  env: {
    _haltproc: exitcode => console.log("Programme halted with code:", exitcode)
  },
  // js: {
  //   table: new WebAssembly.Table({ initial: 10, element: "anyfunc" })
  // }
}

fetch("game.wasm")
.then(res => res.arrayBuffer())
.then(bytes => WebAssembly.instantiate(bytes, importObject))
.then(res => {
  const wasm = res.instance;

  wasm.exports.initBuffer();
  const surfacePtr = wasm.exports.getSurface();
  console.log("Surface pointer", surfacePtr);

  // const memory = new Uint8Array(wasm.exports.memory.surface);
  // const gradient = memory.slice(surfacePtr, surfacePtr + 256);

  // console.log("First few values:", gradient.slice(0, 10))

  // Output on the canvas
  // const imageData = ctx.createImageData(320, 200);
  // for (let b=0; b<200; b++)
  //   for (let a=0; a<320; a++) {
  //     const i = (b * 320 + a) * 4;
  //     const grey = gradient[a % 256]; // wrap around gradient
      
  //     // Order: RGBA
  //     imageData.data[i] = grey;
  //     imageData.data[i+1] = grey;
  //     imageData.data[i+2] = grey;
  //     imageData.data[i+3] = 255;
  //   }

  // ctx.putImageData(imageData, 0, 0)
})
