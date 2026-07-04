{
  Intro Screen unit - Part of Posit-92 game engine
  Hevanafa

  Mandatory for intro screens
}

unit IntroScr;

{$Mode ObjFPC}
{$H+}{$J-}

interface

const
  IntroSlides = 2;

var
  imgPosit92Logo, imgFPCLogo, imgWasmLogo: longint;

procedure SetImgPosit92Logo(const imgHandle: longint); public name 'SetImgPosit92Logo';
procedure SetImgFPCLogo(const imgHandle: longint); public name 'SetImgFPCLogo';
procedure SetImgWasmLogo(const imgHandle: longint); public name 'SetImgWasmLogo';

procedure RenderIntro(const introSlide: smallint);
procedure UnloadIntro;


implementation

uses
  P92Fonts, P92Tex, P92TexDraw, P92VGA;

procedure SetImgPosit92Logo(const imgHandle: longint);
begin
  imgPosit92Logo := imgHandle
end;

procedure SetImgFPCLogo(const imgHandle: longint);
begin
  imgFPCLogo := imgHandle
end;

procedure SetImgWasmLogo(const imgHandle: longint);
begin
  imgWasmLogo := imgHandle
end;

procedure RenderIntro(const introSlide: smallint);
begin
  cls($00000000);

  case introSlide of
    1: begin
      Spr(imgPosit92Logo, 144, 84);
      PrintDefaultCentred('Made with Posit-92', vgaWidth div 2, 126)
    end;

    2: begin
      PrintDefaultCentred('Made with', vgaWidth div 2, 44);

      Spr(imgFPCLogo, 75, 67);
      Spr(imgWasmLogo, 180, 67);

      PrintDefaultCentred('Free Pascal', 108, 144);
      PrintDefaultCentred('Compiler', 108, 154);
      PrintDefaultCentred('WebAssembly', 212, 144);
    end;
  end;

  VgaUpload;
  VgaPresent
end;

procedure UnloadIntro;
begin
  FreeTexture(imgPosit92Logo);
  FreeTexture(imgFPCLogo);
  FreeTexture(imgWasmLogo);
end;

end.
