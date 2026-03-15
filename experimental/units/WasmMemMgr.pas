{
  Wasm Memory Manager - Part of Posit-92 game engine
  Hevanafa
  
  High-level wrapper for WasmHeap
}

unit WasmMemMgr;

{$Mode ObjFPC}
{$Notes OFF}

interface

procedure initHeapMgr;


implementation

uses WasmHeap;

var
  customMemMgr: TMemoryManager;

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
  { Read size before freeing }
  whFreeMemSize := WasmMemSize(p);
  WasmFreeMem(p)
end;

function whReAllocMem(var p: pointer; size: ptruint): pointer;
begin
  whReAllocMem := WasmReAllocMem(p, size)
end;

function whAllocMem(size: ptruint): pointer;
begin
  whAllocMem := WasmAllocMem(size)
end;

function whMemSize(p: pointer): ptruint;
begin
  whMemSize := WasmMemSize(p)
end;

procedure initHeapMgr;
begin
  customMemMgr.GetMem := @whGetMem;
  customMemMgr.FreeMem := @whFreeMem;
  customMemMgr.FreeMemSize := @whFreeMemSize;
  customMemMgr.ReAllocMem := @whReAllocMem;
  customMemMgr.AllocMem := @whAllocMem;
  customMemMgr.MemSize := @whMemSize;

  SetMemoryManager(customMemMgr)
end;

end.
