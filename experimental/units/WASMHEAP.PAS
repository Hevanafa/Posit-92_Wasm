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


implementation

procedure initHeap(const startAddr, heapSize: longword);
begin
  heapStart := PByte(startAddr);
  heapEnd := PByte(startAddr + heapSize);
  heapCurrent := heapStart
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

    current := current + sizeof(TMemBlock) + block^.size
  end;

  { TODO: Implement a new block at heapCurrent }
  WasmGetMem := nil
end;

end.
