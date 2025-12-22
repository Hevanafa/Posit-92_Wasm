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

var
  memmgr: TMemoryManager;

procedure initHeap;
begin
  GetMemoryManager(memmgr);
  SetMemoryManager(memmgr);
end;

procedure helloWorld; external 'env' name 'helloWorld';

procedure testHeap; public name 'testHeap';
var
  p: pointer;
begin
  p := getmem(100);
  if p <> nil then;

  helloWorld;
  
  freemem(p)
end;

procedure init;
begin
  initHeap;
  helloWorld
end;

exports
  init;

begin
{ Starting point is intentionally left empty }
end.
