{ High-level wrapper for WasmHeap }

unit WasmMemMgr;

{$Mode ObjFPC}
{$Memory 1048576, 2 * 1048576}  { 1 MB stack, 1 MB heap }

interface

procedure initMemMgr;


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
  WasmFreeMem(p);
  whFreeMemSize := 0
end;

procedure initMemMgr;
begin
  customMemMgr.GetMem := @whGetMem;
  customMemMgr.FreeMem := @whFreeMem;
  customMemMgr.FreeMemSize := @whFreeMemSize;

  SetMemoryManager(customMemMgr)
end;

end.
