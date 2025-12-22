{ Low-level memory allocator
  Part of Posit-92 game framework }

unit WasmHeap;

interface

type
  { Memory block header }
  PMemBlock = ^TMemBlock;
  TMemBlock = record
    size: longword;
    inUse: boolean;
  end;

var
  heapStart, heapEnd: PByte;
  heapCurrent: PByte;  { where the next new block should go }

procedure initHeap(const startAddr, heapSize: longword); public name 'initHeap';

function WasmGetMem(const bytes: longword): pointer; public name 'WasmGetMem';
procedure WasmFreeMem(const ptr: pointer); public name 'WasmFreeMem';
function GetFreeHeapSize: longword;


implementation

{ uses Logger; }

procedure initHeap(const startAddr, heapSize: longword);
begin
  heapStart := PByte(startAddr);
  heapEnd := PByte(startAddr + heapSize);
  heapCurrent := heapStart;

{
  writeLog('Attempting to call initHeap');
  writeLogI32(longword(heapStart));
  writeLogI32(longword(heapEnd));
  writeLogI32(longword(heapCurrent));
}
end;


function WasmGetMem(const bytes: longword): pointer;
var
  current: PByte;
  block: PMemBlock;
  dataPtr: PByte;
  alignedSize: longword;
begin
  alignedSize := (bytes + 3) and not 3;

  { First-fit search }
  current := heapStart;

  while longword(current) < longword(heapCurrent) do begin
    block := PMemBlock(current);

    if (not block^.inUse) and (block^.size >= alignedSize) then begin
      block^.inUse := true;
      WasmGetMem := pointer(current + sizeof(TMemBlock));
      exit
    end;

    { Find where the next block starts }
    inc(current, sizeof(TMemBlock) + block^.size)
  end;

  { Allocate a new block at heapCurrent }
  block := PMemBlock(heapCurrent);

  if longword(heapCurrent) + sizeof(TMemBlock) + alignedSize > longword(heapEnd) then begin
    { out of memory}
    WasmGetMem := nil;
    exit
  end;

  { Create a new block }
  block^.size := alignedSize;
  block^.inUse := true;

  dataPtr := heapCurrent + sizeof(TMemBlock);
  heapCurrent := dataPtr + alignedSize;

  WasmGetMem := pointer(dataPtr)
end;

procedure WasmFreeMem(const ptr: pointer);
var
  block: PMemBlock;
begin
  if ptr = nil then exit;

  { Find the block header & mark it as free }
  block := PMemBlock(PByte(ptr) - sizeof(TMemBlock));
  block^.inUse := false
end;


function GetFreeHeapSize: longword;
var
  current: PByte;  { current memory offset }
  block: PMemBlock;
  freeBytes: longword;
begin
  freeBytes := 0;

  current := heapStart;
  while longword(current) < longword(heapCurrent) do begin
    block := PMemBlock(current);
    
    if not block^.inUse then
      inc(freeBytes, block^.size);

    inc(current, sizeof(TMemBlock) + block^.size)
  end;

  inc(freeBytes, longword(heapEnd) - longword(heapCurrent));

  GetFreeHeapSize := freeBytes
end;

end.
