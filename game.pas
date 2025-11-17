library Gradient;

{$Mode ObjFPC}

uses Classes;

var
  buffer: array[0..255] of byte;

function FillBuffer: pointer; cdecl; { public name 'FillBuffer'; (use exports instead) }
var
  a: integer;
begin
  for a:=0 to high(buffer) do
    buffer[a] := a;

  fillBuffer := @buffer
end;

exports
  FillBuffer;

begin
{ Starting point is intentionally left empty }
end.

