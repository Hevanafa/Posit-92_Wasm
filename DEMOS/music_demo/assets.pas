unit Assets;

{$Mode ObjFPC}

interface

uses BMFont;

var
  imgCursor: longint;
  imgDosuEXE: array[0..1] of longint;

  imgPlay: longint;
  imgStop: longint;
  imgPause: longint;
  imgVolumeOn, imgVolumeOff: longint;

{ Asset boilerplate }

procedure SetImgCursor(const imgHandle: longint); public name 'SetImgCursor';
procedure SetImgDosuEXE(const imgHandle: longint; const idx: integer); public name 'SetImgDosuEXE';

procedure SetImgPlay(const imgHandle: longint); public name 'SetImgPlay';
procedure SetImgStop(const imgHandle: longint); public name 'SetImgStop';
procedure SetImgPause(const imgHandle: longint); public name 'SetImgPause';
procedure SetImgVolumeOn(const imgHandle: longint); public name 'SetImgVolumeOn';
procedure SetImgVolumeOff(const imgHandle: longint); public name 'SetImgVolumeOff';


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

procedure SetImgPlay(const imgHandle: longint);
begin
  imgPlay := imgHandle
end;

procedure SetImgStop(const imgHandle: longint);
begin
  imgStop := imgHandle
end;

procedure SetImgPause(const imgHandle: longint);
begin
  imgPause := imgHandle
end;

procedure SetImgVolumeOn(const imgHandle: longint);
begin
  imgVolumeOn := imgHandle
end;

procedure SetImgVolumeOff(const imgHandle: longint);
begin
  imgVolumeOff := imgHandle
end;


end.
