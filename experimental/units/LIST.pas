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

procedure TList.Push(item: pointer);
begin
  if count >= capacity then grow;

  PPointer(PByte(items) + count * sizeof(pointer))^ := item;
  inc(count)
end;

end.
