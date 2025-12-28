unit IntroScr;

interface

var
  imgPosit92Logo, imgFPCLogo, imgWasmLogo: longint;

procedure setImgPosit92Logo(const imgHandle: longint); public name 'setImgPosit92Logo';
procedure setImgFPCLogo(const imgHandle: longint); public name 'setImgFPCLogo';
procedure setImgWasmLogo(const imgHandle: longint); public name 'setImgWasmLogo';


implementation

uses Assets, VGA;

procedure setImgPosit92Logo(const imgHandle: longint);
begin
  imgPosit92Logo := imgHandle
end;

procedure setImgFPCLogo(const imgHandle: longint);
begin
  imgFPCLogo := imgHandle
end;

procedure setImgWasmLogo(const imgHandle: longint);
begin
  imgWasmLogo := imgHandle
end;

end.
