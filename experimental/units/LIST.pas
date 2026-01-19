Unit List;

interface

type
  PPointer = ^pointer;

  TList = object
  private
    items: PPointer;
    count: longint;
    capacity: longint;

    procedure Grow;

  public
    procedure Init;
    procedure Done;

    procedure Push(item: pointer);
    function Pop: pointer;
    function Get(index: longint): pointer;

    function Length: longint;
    procedure Clear;
  end;


implementation

procedure TList.Init;
begin
  items := nil;
  count := 0;
  capacity := 0
end;

procedure TList.Done;
begin
  if items <> nil then
    freemem(items);
  items := nil;
  count := 0;
  capacity := 0
end;

procedure TList.Grow;
var
  newCapacity: longint;
  newItems: PPointer;
begin
  newCapacity := capacity + 16;
  getmem(newItems, newCapacity * sizeof(pointer));

  if items <> nil then begin
    move(items^, newItems^, count * sizeof(pointer));
    freemem(items)
  end;

  items := newItems;
  capacity := newCapacity
end;

procedure TList.Push(item: pointer);
begin
  if count >= capacity then grow;

  PPointer(PByte(items) + count * sizeof(pointer))^ := item;
  inc(count)
end;

function TList.Pop: pointer;
begin
  if count = 0 then begin
    pop := nil;
    exit
  end;

  dec(count);
  pop := PPointer(PByte(items) + count * sizeof(pointer))^
end;



end.
