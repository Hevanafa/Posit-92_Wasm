{ 
  Wasm Heap - Part of Posit-92 game engine
  Hevanafa
  Low-level memory allocator
}

{$Mode ObjFPC}
{$J-}

unit WasmHeap;

interface

procedure initHeapRegion(const startAddr, poolSize, heapSize: longword); public name 'initHeapRegion';

function WasmGetMem(const bytes: longword): pointer; public name 'WasmGetMem';
procedure WasmFreeMem(const ptr: pointer); public name 'WasmFreeMem';
function WasmReAllocMem(const ptr: pointer; const newBytes: longword): pointer;
function WasmAllocMem(const bytes: longword): pointer; public name 'WasmAllocMem';

function getHeapSize: longword;
function getFreeHeapSize: longword;


implementation

uses Logger, Conv, Panic;

type
  { Memory block header }
  PMemBlock = ^TMemBlock;
  {$Push}
  {$Align 8}
  TMemBlock = record
    size: longword;
    inUse: boolean;
  end;
  {$Pop}

  PPoolSlot = ^TPoolSlot;
  TPoolSlot = record
    next: PPoolSlot;
  end;

  TBucket = record
    slotSize: longword;
    freeHead: PPoolSlot;
    regionStart: pbyte;
    regionEnd: pbyte;
  end;

const
  HeapAlignment = 8;
  BlockHeaderSize = sizeof(TMemBlock);

  BucketSizes: array[0..5] of longword = (16, 32, 64, 128, 256, 512);
  BucketCount = 6;
  PoolSizeClassMax = 512;

  BucketWeights: array[0..5] of longword = (25, 25, 20, 15, 10, 5);
  TotalWeights = 100;

var
  poolStart, poolEnd: PByte;
  heapStart, heapEnd: PByte;
  heapCurrent: PByte;  { where the next new block should go }

  buckets: array[0..BucketCount-1] of TBucket;

procedure initPool(const poolSize: longword);
var
  b: smallint; { bucket index }
  rollingPtr: PByte;
  regionStart: PByte;  { bucket region start }
  slotCount: longword;
  regionSize: longword;
  i: smallint;
begin
  rollingPtr := poolStart;

  for b:=0 to BucketCount-1 do begin
    regionSize := (poolSize * BucketWeights[b]) div TotalWeights;
    regionStart := rollingPtr;
    slotCount := regionSize div BucketSizes[b];

    buckets[b].slotSize := BucketSizes[b];
    buckets[b].freeHead := PPoolSlot(regionStart);

    buckets[b].regionStart := regionStart;
    buckets[b].regionEnd := pbyte(longword(regionStart) + regionSize);

    for i:=0 to slotCount - 2 do begin
      PPoolSlot(rollingPtr)^.next := PPoolSlot(rollingPtr + BucketSizes[b]);
      inc(rollingPtr, BucketSizes[b])
    end;

    { Last slot points to nil }
    PPoolSlot(rollingPtr)^.next := nil;
    inc(rollingPtr, BucketSizes[b])
  end;
end;

procedure initHeapRegion(const startAddr, poolSize, heapSize: longword);
begin
  poolStart := PByte(startAddr);
  poolEnd := PByte(startAddr + poolSize);

  heapStart := poolEnd;
  heapEnd := PByte(longword(heapStart) + heapSize);
  heapCurrent := heapStart;

  initPool(poolSize)
end;


function findBucket(const bytes: longword): smallint;
var
  a: word;
begin
  result := -1;

  for a:=0 to BucketCount-1 do
    if BucketSizes[a] >= bytes then begin
      result := a;
      exit
    end;
end;

function findBucketByPtr(const ptr: pointer): smallint;
var
  b: smallint;
begin
  result := -1;

  for b:=0 to BucketCount-1 do
    if (LongWord(ptr) >= longword(buckets[b].regionStart))
      and (longword(ptr) < longword(buckets[b].regionEnd)) then begin
        result := b;
        exit
      end;
end;


function poolAlloc(const bytes: LongWord): pointer;
var
  b: smallint;
  slot: PPoolSlot;
begin
  b := findBucket(bytes);

  if b = -1 then panicHalt('poolAlloc: Unable to allocate a bucket!');

  if buckets[b].freeHead = nil then
    panicHalt('poolAlloc: No free buckets!');

  slot := buckets[b].freeHead;
  buckets[b].freeHead := slot^.next;
  result := Pointer(slot)
end;

procedure poolFree(const ptr: pointer);
var
  b: smallint;
  slot: PPoolSlot;
begin
  b := findBucketByPtr(ptr);

  if b = -1 then panicHalt('poolFree: ' + i32str(longword(ptr)) + 'doesn''t belong to the pool region!');

  slot := PPoolSlot(ptr);
  slot^.next := buckets[b].freeHead;
  buckets[b].freeHead := slot
end;

function WasmGetMem(const bytes: longword): pointer;
var
  current: PByte;
  block: PMemBlock;
  dataPtr: PByte;
  alignedSize: longword;
begin
  alignedSize := (bytes + (HeapAlignment - 1)) and not (HeapAlignment - 1);

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
    { out of memory }
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

  alignedSize := (newBytes + (HeapAlignment - 1)) and not (HeapAlignment - 1);
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
