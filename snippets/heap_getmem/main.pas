{
  Compile:
  E:\fpc-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded .\main.pas
  remove-item .\main.wasm; rename-item "main" "main.wasm"

  Run:
  npx http-server
}

library Main;

{$Mode ObjFPC}
{$Memory 1024, 1048576}  { 1 KB stack, 1 MB heap }

uses WasmHeap;

function whGetMem(size: ptruint): pointer;
begin
  whGetMem := WasmGetMem(size)
end;

function whFreeMem(p: pointer): ptruint;
begin
  WasmFreeMem(p);
  whFreeMem := 0
end;

function whFreeMemSize(p: pointer; size: ptruint): ptruint;
begin
  WasmFreeMem(p);
  whFreeMemSize := 0
end;



var
  customMemMgr: TMemoryManager;

procedure initCustomHeap;
begin
  customMemMgr.GetMem := @whGetMem;
  customMemMgr.FreeMem := @whFreeMem;
  customMemMgr.FreeMemSize := @whFreeMemSize;

  SetMemoryManager(customMemMgr)
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
  initCustomHeap;
  testHeap;
  helloWorld
end;

exports
  init;

begin
{ Starting point is intentionally left empty }
end.
