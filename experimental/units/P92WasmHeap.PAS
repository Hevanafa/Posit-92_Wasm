{ 
  Wasm Heap - Part of Posit-92 game engine
  Hevanafa
  Low-level memory allocator
}

{
  Memory layout (2MB default)
  0x000000..0x02FFFF	Pascal stack	(192KB)
  0x030000..0x06E7FF	Video memory	(320x200x4, depending on vgaWidth and vgaHeight)
  0x06E800..0x0EE7FF	Small heap region	(512KB, two-tier tier 1)
  0x0EE800..0x1EE7FF	Large heap region	(0x100000 bytes, two-tier tier 2)
  0x1EE801..0x200000    Unused
}

unit P92WasmHeap;

{$Mode ObjFPC}
{$H+}{$J-}
{$WARN 4056 off : Conversion between ordinals and pointers is not portable}

interface

procedure InitHeapRegion(const startAddr, smallHeapSize, aLargeHeapSize: longword); public name 'InitHeapRegion';

function WasmGetMem(const bytes: longword): pointer; public name 'WasmGetMem';
procedure WasmFreeMem(const ptr: pointer); public name 'WasmFreeMem';
function WasmReAllocMem(const ptr: pointer; const newBytes: longword): pointer;
function WasmAllocMem(const bytes: longword): pointer; public name 'WasmAllocMem';
function WasmMemSize(const ptr: pointer): PtrUInt;

procedure JsReportSize(requestedSize: longint); external 'env' name 'JsReportSize';

{ Debug functions }
function GetBucketAllocStart: longword;
function GetBucketAllocEnd: longword;


implementation

uses P92Conversions, P92Panic;

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

  { Large heap: buddy allocator }
  PFreeBlock = ^TFreeBlock;
  TFreeBlock = record
    prev, next: PFreeBlock;
  end;


var
  largeHeapSize: longword;

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
  PoolSizeClassMax = 512;


{ Weight distribution across buckets

  Weighted toward smaller buckets since the engine profile is
  many of small objects rather than few large ones

  The sum must match to TotalWeights }
  BucketWeights: array[0..5] of longword = (25, 25, 20, 15, 10, 5);
  TotalWeights = 100;

var
  bucketAllocStart, bucketAllocEnd: PByte;
  buckets: array[0..BucketCount-1] of TBucket;

const
  BuddyMinOrder = 9;  { 512 bytes }
  BuddyMaxOrder = 20;  { 1 MB }
  BuddyOrderCount = BuddyMaxOrder - BuddyMinOrder + 1;

{ Large heap }
var
  freeLists: array[0..BuddyOrderCount - 1] of PFreeBlock;
  buddyBase: PByte;
  splitBitmap: PByte;

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


function CalcBitmapSize(size: longword): longword;
var
  totalBits: longword;
  order: smallint;
begin
  totalBits := 0;

  for order := BuddyMinOrder to BuddyMaxOrder - 1 do
    totalBits := totalBits + (size shr (order + 1));

  CalcBitmapSize := (totalBits + 7) shr 3
end;

function BitmapOffset(order: integer): longword;
var
  bits: longword;
  { order iterator }
  o: smallint;
begin
  bits := 0;

  for o:=BuddyMinOrder to order - 1 do
    inc(bits, largeHeapSize shr(o + 1));

  BitmapOffset := bits
end;

procedure InsertFree(orderIndex: smallint; block: PByte); forward;

procedure InitBuddyAllocator(base: PByte; size: longword);
var
  bitmapBytes: longword;
  a: word;
begin
  buddyBase := base;

  for a:=0 to BuddyOrderCount - 1 do
    freeLists[a] := nil;

  bitmapBytes := CalcBitmapSize(size);
  splitBitmap := base;
  FillByte(splitBitmap^, bitmapBytes, 0);

  { Align to the next 16-byte boundary }
  buddyBase := PByte((PtrUInt(base) + bitmapBytes + 15) and not 15);
  InsertFree(BuddyOrderCount - 1, buddyBase)
end;

{ Buddy address calculation }
function BuddyOf(block: PByte; order: integer): PByte;
begin
  BuddyOf := PByte(PtrUInt(block - buddyBase) xor (1 shl (order + BuddyMinOrder)) + PtrUInt(buddyBase));
end;

procedure InitHeapRegion(const startAddr, smallHeapSize, aLargeHeapSize: longword);
begin
  bucketAllocStart := PByte(startAddr);
  bucketAllocEnd := PByte(startAddr + smallHeapSize);
  InitPool(smallHeapSize);

  { Round down to a power of 2 without using the Math unit }
  largeHeapSize := aLargeHeapSize;

  largeHeapSize := largeHeapSize or (largeHeapSize shr 1);
  largeHeapSize := largeHeapSize or (largeHeapSize shr 2);
  largeHeapSize := largeHeapSize or (largeHeapSize shr 4);
  largeHeapSize := largeHeapSize or (largeHeapSize shr 8);
  largeHeapSize := largeHeapSize or (largeHeapSize shr 16);
  largeHeapSize := (largeHeapSize shr 1) + 1;

  InitBuddyAllocator(pbyte(startAddr + smallHeapSize), largeHeapSize);
end;


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

  if b = -1 then PanicHalt('poolAlloc: Unable to allocate a bucket!');

  if buckets[b].freeHead = nil then
    PanicHalt('poolAlloc: No free buckets!');

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


procedure InsertFree(orderIndex: smallint; block: PByte);
var
  fb: PFreeBlock;
begin
  fb := PFreeBlock(block);
  fb^.next := freeLists[orderIndex];
  fb^.prev := nil;

  if freeLists[orderIndex] <> nil then
    freeLists[orderIndex]^.prev := fb;

  freeLists[orderIndex] := fb;
end;

procedure RemoveFree(orderIndex: smallint; block: PByte);
var
  fb: PFreeBlock;
begin
  fb := PFreeBlock(block);

  if fb^.prev <> nil then
    fb^.prev^.next := fb^.next
  else
    freeLists[orderIndex] := fb^.next;

  if fb^.next <> nil then
    fb^.next^.prev := fb^.prev;
end;


function WasmGetMem(const bytes: longword): pointer;
begin
{$ifdef P92_DEBUG_HEAP}
  JsReportSize(bytes);
{$endif}

  if bytes <= PoolSizeClassMax then begin
    WasmGetMem := PoolAlloc(bytes);
    exit
  end;

  { TODO: Implement for the buddy allocator}
end;


{
  Order:
  * Mark block as free
  * Check backward: if the previous block is free, merge into it
  * Check forward: merge into it if the next block is free
}
procedure WasmFreeMem(const ptr: pointer);
begin
  if ptr = nil then exit;

  if (longword(ptr) >= longword(bucketAllocStart))
    and (longword(ptr) < longword(bucketAllocEnd)) then begin
    PoolFree(ptr);
    exit
  end;

  { TODO: Implement for the buddy allocator }
end;


function WasmReAllocMem(const ptr: pointer; const newBytes: longword): pointer;
begin
  if (longword(ptr) >= longword(bucketAllocStart))
    and (longword(ptr) < longword(bucketAllocEnd)) then begin
      WasmReAllocMem := PoolAlloc(newBytes);

      if WasmReAllocMem <> nil then begin
        move(ptr^, WasmReAllocMem^, newBytes);
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

  { TODO: Implement for the buddy allocator }
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

  { TODO: Implement for the buddy allocator }
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

