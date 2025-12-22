{
  Compile:
  E:\fpc-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded .\main.pas
  remove-item .\main.wasm; rename-item "main" "main.wasm"

  Run:
  npx http-server
}

library Main;

uses WasmMemMgr;

procedure helloWorld; external 'env' name 'helloWorld';

procedure testHeap;
var
  p: pointer;
begin
  p := getmem(100);
  if p <> nil then;
  freemem(p)
end;

procedure init;
begin
  initMemMgr;
  testHeap;
  helloWorld
end;

exports
  init;

begin
{ Starting point is intentionally left empty }
end.
