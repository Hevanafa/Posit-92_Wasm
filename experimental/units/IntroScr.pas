{
  Intro Screen unit - Part of Posit-92 game engine
  Hevanafa

  Mandatory for intro screens
}

unit IntroScr;

{$Mode TP}
{$J-}  { Switch off assignments to typed constants }

interface

const
  IntroSlides = 2;

var
  imgPosit92Logo, imgFPCLogo, imgWasmLogo: longint;

procedure setImgPosit92Logo(const imgHandle: longint); public name 'setImgPosit92Logo';
procedure setImgFPCLogo(const imgHandle: longint); public name 'setImgFPCLogo';
procedure setImgWasmLogo(const imgHandle: longint); public name 'setImgWasmLogo';

procedure renderIntro(const introSlide: integer);
procedure unloadIntro;


implementation

uses
  Assets, ImgRef, ImgRefFast, VGA;

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

procedure renderIntro(const introSlide: integer);
begin
  cls($FF000000);

  case introSlide of
    1: begin
      spr(imgPosit92Logo, 144, 84);
      printDefaultCentred('Made with Posit-92', vgaWidth div 2, 126)
    end;

    2: begin
      printDefaultCentred('Made with', vgaWidth div 2, 44);

      spr(imgFPCLogo, 75, 67);
      spr(imgWasmLogo, 180, 67);

      printDefaultCentred('Free Pascal', 108, 144);
      printDefaultCentred('Compiler', 108, 154);
      printDefaultCentred('WebAssembly', 212, 144);
    end;
  end;

  vgaFlush
end;

procedure unloadIntro;
begin
  freeImage(imgPosit92Logo);
  freeImage(imgFPCLogo);
  freeImage(imgWasmLogo);
end;

end.
