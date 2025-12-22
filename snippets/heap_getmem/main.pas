{
  Compile:
  E:\fpc-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded .\main.pas
  remove-item .\main.wasm; rename-item "main" "main.wasm"

  Run:
  npx http-server
}

library Main;

{$Mode TP}
{$Memory 1024, 1048576}  { 1 KB stack, 1 MB heap }

uses HeapMgr;

procedure helloWorld; external 'env' name 'helloWorld';

procedure testHeap; public name 'testHeap';
var
  p: pointer;
begin
  p := getmem(100);
  if p <> nil then;
  freemem(p)
end;

procedure init;
begin
  helloWorld
end;

exports
  init;

begin
{ Starting point is intentionally left empty }
end.
