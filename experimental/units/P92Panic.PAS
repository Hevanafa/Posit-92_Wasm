{
  Panic unit
  Part of Posit-92 game engine
  By Hevanafa

  Mainly used to halt the program immediately & output an error message to the console
}

unit P92Panic;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }

interface

{$ifdef P92_WASM}
procedure JsPanicHalt(const textPtr: PChar; const textLen: word); external 'env' name 'JsPanicHalt';
{$endif}

procedure PanicHalt(const msg: AnsiString);


implementation

{$ifdef P92_WASM}
uses P92VGA;

procedure PanicHalt(const msg: AnsiString);
begin
  JsPanicHalt(@msg[1], length(msg));
  halt(1)
end;
{$endif}

{$ifdef P92_SDL2}
uses P92Logger, Windows;

procedure PanicHalt(const msg: AnsiString);
var
  s: string;
begin
  s := 'PANIC: ' + msg + #0;
  MessageBox(0, PChar(@s[1]), 'Panic', MB_OK or MB_ICONERROR);
  halt(1)
end;
{$endif}

end.
