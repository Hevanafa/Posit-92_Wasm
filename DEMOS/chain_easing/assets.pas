unit Assets;

{$Mode ObjFPC}

interface

var
  imgCursor, imgBlinky: longint;
  imgDosuEXE: array[0..1] of longint;

{ Asset boilerplate }
procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
procedure setImgBlinky(const imgHandle: longint); public name 'setImgBlinky';
procedure setImgDosuEXE(const imgHandle: longint; const idx: integer); public name 'setImgDosuEXE';


implementation

procedure setImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure setImgBlinky(const imgHandle: longint);
begin
  imgBlinky := imgHandle
end;

procedure setImgDosuEXE(const imgHandle: longint; const idx: integer);
begin
  imgDosuEXE[idx] := imgHandle
end;

end.
