Unit List;

interface

type
  PPointer = ^PPointer;

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

end.
