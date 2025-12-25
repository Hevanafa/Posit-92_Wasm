unit Assets;

{$Mode TP}

interface

var
  imgCursor: longint;
  imgCGAFont: longint;

{ Asset boilerplate }
procedure setImgCursor(const imgHandle: longint); public name 'setImgCursor';
procedure setImgCGAFont(const imgHandle: longint); public name 'setImgCGAFont';


implementation

uses Conv;

{ Begin asset boilerplate }

procedure setImgCursor(const imgHandle: longint);
begin
  imgCursor := imgHandle
end;

procedure setImgCGAFont(const imgHandle: longint);
begin
  imgCGAFont := imgHandle
end;


end.