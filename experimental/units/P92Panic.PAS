{
  Panic unit
  Part of Posit-92 game engine
  By Hevanafa

  Mainly used to halt the program immediately & output an error message to the console
}

unit P92Panic;

{$Mode ObjFPC}
{$H-}{$J-}

interface

{$ifdef P92_WASM}
procedure JsPanicHalt(const textPtr: PChar; const textLen: word); external 'env' name 'JsPanicHalt';
{$endif}

procedure PanicHalt(const msg: string);


implementation

{$ifdef P92_WASM}
uses P92VGA;
{$endif}
{$ifdef Windows}
uses Logger, Windows;
{$endif}


{$ifdef Windows}
procedure panicHalt(const msg: string);
var
  s: string;
  p: pchar;
begin
  s := 'PANIC: ' + msg + #0;
  MessageBox(0, PChar(@s[1]), 'Panic', MB_OK or MB_ICONERROR);
  halt(1)
end;

{$else}

procedure PanicHalt(const msg: string);
begin
  JsPanicHalt(@msg[1], length(msg));
  halt(1)
end;
{$endif}

end.
