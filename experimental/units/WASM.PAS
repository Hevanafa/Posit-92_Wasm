unit Wasm;

interface

function WasmGetMem(const bytes: longword): longword; external 'env' name 'wasmgetmem';

implementation

end.