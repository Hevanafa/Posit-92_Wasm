unit Assets;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses P92BMFont;

var
  imgCursor: longint;
  imgDosuExe: array[0..1] of longint;

{ Asset boilerplate }
procedure SetImgCursor(const imgHandle: longint); public name 'SetImgCursor';
procedure SetImgDosuExe(const imgHandle: longint; const idx: integer); public name 'SetImgDosuExe';


implementation

uses P92Conversions;

{ Begin asset boilerplate }

procedure SetImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure SetImgDosuExe(const imgHandle: longint; const idx: integer);
begin
  imgDosuExe[idx] := imgHandle
end;

end.
