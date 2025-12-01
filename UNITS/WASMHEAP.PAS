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


implementation

procedure initHeap(const startAddr, heapSize: longword); public name 'initHeap';
begin
  heapStart := PByte(startAddr);
  heapEnd := PByte(startAddr + heapSize);
  heapCurrent := heapStart
end;

end.
