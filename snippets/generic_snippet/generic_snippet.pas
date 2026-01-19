
{$Mode ObjFPC}

uses UUnit;

type
  aRecord = record
    x, y: integer;
  end;

var
  thing: specialize TGeneric<aRecord>;

begin
  writeln('Hello from generic!');
end.
