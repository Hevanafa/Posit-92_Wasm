unit Assets;

{$Mode ObjFPC}

interface

uses BMFont;

const
  { Must be the same as JS code }
  SfxBwonk = 1;
  SfxBite = 2;
  SfxBonk = 3;
  SfxStrum = 4;
  SfxSlip = 5;

var
  imgCursor: longint;
  imgDosuExe: array[0..1] of longint;

procedure SetImgCursor(const imgHandle: longint); public name 'SetImgCursor';
procedure SetImgDosuExe(const imgHandle: longint; const idx: integer); public name 'SetImgDosuExe';


implementation

uses Conv;

procedure SetImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure SetImgDosuExe(const imgHandle: longint; const idx: integer);
begin
  imgDosuExe[idx] := imgHandle
end;

end.
