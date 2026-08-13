unit ObjectTests;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses
  SysUtils;

type
  TEntity = class
    X, Y: single;
    Name: string;

    constructor Create(const aName: string; const aX, aY: single);
    destructor Destroy; override;
  end;

procedure TestSingleInstance;


implementation

uses P92Logger;

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

