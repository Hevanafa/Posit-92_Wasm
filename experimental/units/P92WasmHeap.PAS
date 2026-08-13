{ 
  Wasm Heap - Part of Posit-92 game engine
  Hevanafa
  Low-level memory allocator
}

{
  Memory layout (2MB default)
  0x000000..0x02FFFF	Pascal stack	(192KB)
  0x030000..0x06E7FF	Video memory	(320x200x4, depending on vgaWidth and vgaHeight)
  0x06E800..0x0EE7FF	Slab tier region	(512KB, two-tier tier 1)
  0x0EE800..0x200000	Reserved region	(at least 0x100000 bytes, two-tier tier 2)
}

unit P92WasmHeap;

{$Mode ObjFPC}
{$H-}{$J-}
{$WARN 4056 off : Conversion between ordinals and pointers is not portable}
{$DEFINE P92_DEBUG_HEAP}

interface

procedure InitHeapRegion(const startAddr, smallHeapSize, aLargeHeapSize: longword); public name 'InitHeapRegion';

function WasmGetMem(const bytes: longword): pointer; public name 'WasmGetMem';
procedure WasmFreeMem(const ptr: pointer); public name 'WasmFreeMem';
function WasmReAllocMem(const ptr: pointer; const newBytes: longword): pointer;
function WasmAllocMem(const bytes: longword): pointer; public name 'WasmAllocMem';
function WasmMemSize(const ptr: pointer): PtrUInt;

procedure JsReportGetMem(bytes: longint); external 'env' name 'JsReportGetMem';
procedure JsReportFreeMem(bytes: longint); external 'env' name 'JsReportFreeMem';

{ Debug functions }
function GetBucketAllocStart: longword;
function GetBucketAllocEnd: longword;


implementation

uses P92Logger, P92Conversions, P92Panic;

type
  { Small heap: bucket allocator }
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

  { Large heap: Free list }
  PBlockHeader = ^TBlockHeader;
  TBlockHeader = record
    size: longword;
    isFree: boolean;
    prev: PBlockHeader;
    next: PBlockHeader;
  end;

  PBlockFooter = ^TBlockFooter;
  TBlockFooter = record
    size: longword;
    isFree: boolean;
  end;


{ Small heap }

const
{ Fixed slot sizes for tier 1 pool buckets, in bytes

  Covers typical small FPC allocations:
  * 16: object headers, VMT pointers
  * 32: typical AnsiString headers & small list nodes
  * 64: small class instances or short string buffers
  * 128: medium objects
  * 256: larger objects
}
  BucketSizes: array[0..4] of longword = (16, 32, 64, 128, 256);
  BucketCount = 5;


{ Allocations at or below this size go to tier 1 pool

  Anything above this goes to tier 2 free-list heap

  This must match the largest value in BucketSizes }
  PoolSizeClassMax = 256;


{ Weight distribution across buckets

  Weighted toward smaller buckets since the engine profile is
  many of small objects rather than few large ones

  The sum must match to TotalWeights }
  BucketWeights: array[0..4] of longword = (30, 25, 20, 15, 10);
  TotalWeights = 100;

var
  bucketAllocStart, bucketAllocEnd: PByte;
  buckets: array[0..BucketCount-1] of TBucket;


{ Free-list allocation }


procedure InitPool(const poolSize: longword);
var
  b: smallint; { bucket index }
  rollingPtr: PByte;
  regionStart: PByte;  { bucket region start }
  slotCount: longword;
  regionSize: longword;
  i: smallint;
begin
  rollingPtr := bucketAllocStart;

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


{ Small heap implementation }

function FindBucket(const bytes: longword): smallint;
var
  a: word;
begin
  FindBucket := -1;

  for a:=0 to BucketCount-1 do
    if BucketSizes[a] >= bytes then begin
      FindBucket := a;
      exit
    end;
end;

function FindBucketByPtr(const ptr: pointer): smallint;
var
  b: smallint;
begin
  FindBucketByPtr := -1;

  for b:=0 to BucketCount-1 do
    if (LongWord(ptr) >= longword(buckets[b].regionStart))
      and (longword(ptr) < longword(buckets[b].regionEnd)) then begin
        FindBucketByPtr := b;
        exit
      end;
end;


function PoolAlloc(const bytes: LongWord): pointer;
var
  b: smallint;
  slot: PPoolSlot;
begin
  b := FindBucket(bytes);

  if b = -1 then
    PanicHalt('PoolAlloc: Unable to allocate a bucket! Requested size: ' + I32Str(bytes));

  if buckets[b].freeHead = nil then
    PanicHalt('PoolAlloc: No free buckets!');

  slot := buckets[b].freeHead;
  buckets[b].freeHead := slot^.next;
  PoolAlloc := pointer(slot)
end;

procedure PoolFree(const ptr: pointer);
var
  b: smallint;
  slot: PPoolSlot;
begin
  b := FindBucketByPtr(ptr);

  if b = -1 then PanicHalt('poolFree: ' + I32Str(longword(ptr)) + 'doesn''t belong to the pool region!');

  slot := PPoolSlot(ptr);
  slot^.next := buckets[b].freeHead;
  buckets[b].freeHead := slot
end;


{ Large allocator }

function NextBlockInMemory(header: PBlockHeader): PBlockHeader;
begin
  NextBlockInMemory := PBlockHeader(
    PByte(header) + sizeof(TBlockHeader) + header^.size + sizeof(TBlockFooter)
  );
end;

function PrevBlockInMemory(header: PBlockHeader): PBlockHeader;
var
  prevFooter: PBlockFooter;
begin
  prevFooter := PBlockFooter(pbyte(header) - sizeof(TBlockFooter));

  PrevBlockInMemory := PBlockHeader(
    PByte(header) - sizeof(TBlockFooter) - prevFooter^.size - sizeof(TBlockHeader)
  )
end;




{ Begin generic allocator functions }

function WasmGetMem(const bytes: longword): pointer;
begin
{$ifdef P92_DEBUG_HEAP}
  JsReportGetMem(bytes);
{$endif}

  if bytes <= PoolSizeClassMax then begin
    WasmGetMem := PoolAlloc(bytes);
    exit
  end;

  { TODO: Implement the large allocator call }
end;


procedure WasmFreeMem(const ptr: pointer);
begin
  if ptr = nil then exit;

  if (longword(ptr) >= longword(bucketAllocStart))
    and (longword(ptr) < longword(bucketAllocEnd)) then begin
    PoolFree(ptr);
    exit
  end;

  { TODO: Implement the large allocator call }
end;


function WasmReAllocMem(const ptr: pointer; const newBytes: longword): pointer;
var
  b: smallint;
  oldSize: longword;
begin
  if (longword(ptr) >= longword(bucketAllocStart))
    and (longword(ptr) < longword(bucketAllocEnd)) then begin
      b := FindBucketByPtr(ptr);
      oldSize := buckets[b].slotSize;

      WasmReAllocMem := WasmGetMem(newBytes);

      if WasmReAllocMem <> nil then begin
        if newBytes < oldSize then
          move(ptr^, WasmReAllocMem^, newBytes)
        else
          move(ptr^, WasmReAllocMem^, oldSize);

        PoolFree(ptr)
      end;

      exit
    end;

  if ptr = nil then begin
    WasmReAllocMem := WasmGetMem(newBytes);
    exit
  end;

  if newBytes = 0 then begin
    WasmFreeMem(ptr);
    WasmReAllocMem := nil;
    exit
  end;

  { TODO: Implement the large allocator call }
end;


function WasmAllocMem(const bytes: longword): pointer;
begin
  WasmAllocMem := WasmGetMem(bytes);

  if WasmAllocMem <> nil then
    fillchar(WasmAllocMem^, bytes, 0)
end;

function WasmMemSize(const ptr: pointer): PtrUInt;
var
  idx: smallint;
begin
  if ptr = nil then begin
    WasmMemSize := 0;
    exit
  end;

  { Pool: Find which bucket owns this address }
  idx := FindBucketByPtr(ptr);
  if idx >=0 then begin
    WasmMemSize := buckets[idx].slotSize;
    exit
  end;

  { TODO: Implement the large allocator call }
end;

procedure InitHeapRegion(const startAddr, smallHeapSize, aLargeHeapSize: longword);
begin
  bucketAllocStart := PByte(startAddr);
  bucketAllocEnd := PByte(startAddr + smallHeapSize);
  InitPool(smallHeapSize);

  { TODO: Implement the large allocator call }
end;


function GetBucketAllocStart: longword;
begin
  GetBucketAllocStart := longword(bucketAllocStart)
end;

function GetBucketAllocEnd: longword;
begin
  GetBucketAllocEnd := longword(bucketAllocEnd)
end;

end.

