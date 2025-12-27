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

procedure initHeap(const startAddr, heapSize: longword); public name 'initHeap';

function WasmGetMem(const bytes: longword): pointer; public name 'WasmGetMem';
procedure WasmFreeMem(const ptr: pointer); public name 'WasmFreeMem';
function WasmReAllocMem(const ptr: pointer; const newBytes: longword): pointer;
function WasmAllocMem(const bytes: longword): pointer; public name 'WasmAllocMem';

function getHeapSize: longword;
function getFreeHeapSize: longword;


implementation

{ uses Logger; }

var
  heapStart, heapEnd: PByte;
  heapCurrent: PByte;  { where the next new block should go }

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
  block, nextBlock: PMemBlock;
begin
  if ptr = nil then exit;

  { Find the block header & mark it as free }
  block := PMemBlock(PByte(ptr) - sizeof(TMemBlock));
  block^.inUse := false;

  { Forward memory coalescing logic }
  nextBlock := PMemBlock(pbyte(block) + sizeof(TMemBlock) + block^.size);

  { Check if the next block exists and is free }
  if (longword(nextBlock) < longword(heapCurrent))
    and (not nextBlock^.inUse) then
    inc(block^.size, sizeof(TMemBlock) + nextBlock^.size);
end;


function WasmReAllocMem(const ptr: pointer; const newBytes: longword): pointer;
var
  oldBlock, nextBlock: PMemBlock;
  newPtr: pointer;
  copySize, alignedSize, availableSpace: longword;
begin
  if ptr = nil then begin
    WasmReAllocMem := WasmGetMem(newBytes);
    exit
  end;

  if newBytes = 0 then begin
    WasmFreeMem(ptr);
    WasmReAllocMem := nil;
    exit
  end;

  alignedSize := (newBytes + 3) and not 3;
  oldBlock := PMemBlock(PByte(ptr) - sizeof(TMemBlock));

  { Handle shrink in-place }
  if alignedSize <= oldBlock^.size then begin
    oldBlock^.size := alignedSize;
    WasmReAllocMem := ptr;
    exit
  end;

  { Handle expand in-place if available }
  nextBlock := PMemBlock(PByte(oldBlock) + sizeof(TMemBlock) + oldBlock^.size);

  if (longword(nextBlock) < longword(heapCurrent)) and not nextBlock^.inUse then begin
    availableSpace := oldBlock^.size + sizeof(TMemBlock) + nextBlock^.size;

    if alignedSize <= availableSpace then begin
      oldBlock^.size := alignedSize;
      WasmReAllocMem := ptr;
      exit
    end;
  end;

  { Can't expand in-place, do full realloc }
  newPtr := WasmGetMem(newBytes);
  if newPtr = nil then begin
    WasmReAllocMem := nil;
    exit
  end;

  copySize := oldBlock^.size;
  if copySize > newBytes then copySize := newBytes;
  move(ptr^, newPtr^, copySize);

  WasmFreeMem(ptr);
  WasmReAllocMem := newPtr
end;


function WasmAllocMem(const bytes: longword): pointer;
begin
  WasmAllocMem := WasmGetMem(bytes);
  if WasmAllocMem <> nil then
    fillchar(WasmAllocMem^, bytes, 0)
end;


function getHeapSize: longword;
begin
  getHeapSize := heapEnd - heapStart
end;

function getFreeHeapSize: longword;
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
