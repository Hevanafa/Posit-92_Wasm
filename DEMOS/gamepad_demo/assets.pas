unit Assets;

{$Mode ObjFPC}

interface

uses BMFont;

var
  greyFont: TBMFont;

  imgCursor: longint;
  imgDosuEXE: array[0..1] of longint;

procedure SetImgCursor(const imgHandle: longint); public name 'SetImgCursor';
procedure SetImgDosuEXE(const imgHandle: longint; const idx: integer); public name 'SetImgDosuEXE';


implementation

uses Conv;

procedure SetImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure SetImgDosuEXE(const imgHandle: longint; const idx: integer);
begin
  imgDosuEXE[idx] := imgHandle
end;

end.
