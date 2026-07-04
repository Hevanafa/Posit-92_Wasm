unit Assets;

{$Mode ObjFPC}
{$H+}{$J-}

interface

var
  imgCursor: longint;
  imgDosuEXE: array[0..1] of longint;

{ Asset boilerplate }
procedure SetImgCursor(const imgHandle: longint); public name 'SetImgCursor';
procedure SetImgDosuEXE(const imgHandle: longint; const idx: integer); public name 'SetImgDosuEXE';


implementation

{ Begin asset boilerplate }

procedure setImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure setImgDosuEXE(const imgHandle: longint; const idx: integer);
begin
  imgDosuEXE[idx] := imgHandle
end;

end.
