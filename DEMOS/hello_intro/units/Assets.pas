unit Assets;

{$Mode ObjFPC}

interface

var
  imgCursor: longint;
  imgDosuEXE: array[0..1] of longint;


implementation

procedure SetImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure SetImgDosuEXE(const imgHandle: longint; const idx: integer);
begin
  imgDosuEXE[idx] := imgHandle
end;

end.
