unit ObjectTests;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses
  Classes, SysUtils;

type

  { TEntity }

  TEntity = class
    X, Y: single;
    Name: string;

    constructor Create(const aName: string; const aX, aY: single);
    destructor Destroy; override;
  end;


implementation

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

