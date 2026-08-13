unit ObjectTests;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses
  SysUtils, FGL;
  { Classes unit is optional for the class syntax }

type
  TEntity = class
    X, Y: single;
    Name: string;

    constructor Create(const aName: string; const aX, aY: single);
    destructor Destroy; override;
  end;

  TEntityList = specialize TFPGObjectList<TEntity>;

procedure TestSingleInstance;
procedure TestObjectList;


implementation

uses P92Logger, P92Conversions;

procedure Assert(cond: boolean; const msg: string);
begin
  if not cond then begin
    writelog('Assert failed: ' + msg);
    halt(1)
  end;
end;

procedure TestSingleInstance;
var
  e: TEntity;
begin
  writelog('Begin TestSingleInstance');

  e := TEntity.create('Player', 10.0, 20.0);

  assert(e <> nil, 'Create failed');
  assert(e.name = 'Player', 'Name mismatch');
  assert(e.x = 10.0, 'x mismatch');

  e.free;

  writelog('End of TestSingleInstance');
end;

procedure TestObjectList;
var
  list: TEntityList;
  a: smallint;
  e: TEntity;
begin
  writelog('Begin TestObjectList');

  list := TEntityList.create(true);  { makes it own objects }

  for a:=1 to 100 do
    list.add(
      TEntity.create('Entity' + I32Str(a), a * 1.0, a * 2.0));

  writelog('What''s the count? ' + i32str(list.count));
  assert(list.count = 100, 'Count mismatch');

  { Random access test }
  assert(list[50].Name = 'Entity51', 'Lookup failed');

  writelog('Attempting to delete index 25');
  list.delete(25);

  writelog('What''s the count? ' + i32str(list.count));

  writelog('Attempting to clear');
  list.clear;

  writelog('Count after clear: ' + i32str(list.count));

  for a:=1 to 40 do
    list.add(
      TEntity.create('Entity' + I32Str(a), a * 1.0, a * 2.0));

  writelog('Refill count: ' + i32str(list.count));

  list.free;

  writelog('End of TestObjectList');
end;

{ TEntity }

constructor TEntity.Create(const aName: string; const aX, aY: single);
begin
  inherited Create;

  name := aname;
  x := ax;
  y := ay;
end;

destructor TEntity.Destroy;
begin
  Name := '';  { Force string dealloc }
  inherited Destroy
end;

end.

