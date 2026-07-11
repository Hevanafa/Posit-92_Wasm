{
  Logger - Part of Posit-92 game engine
  Hevanafa

  Trimmed down version of LOGGER.PAS from Posit-92
}

unit P92Logger;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }

interface

{$ifdef P92_WASM}
{ Must be registered in importObject }
procedure WriteLogI32(const value: longint); external 'env' name 'WriteLogI32';
procedure WriteLogF32(const value: double); external 'env' name 'WriteLogF32';
procedure FlushLog; external 'env' name 'FlushLog';
{$endif}

{$ifdef P92_SDL2}
procedure InitLogger;
procedure CloseLogger;

procedure WriteLogI32(const value: longint);
procedure WriteLogF32(const value: double);
procedure WriteWarn(const msg: string);
{$endif}

procedure WriteLog(const msg: string);


implementation

{$ifdef P92_WASM}
uses P92InteropBuf;
{$endif}

{$ifdef P92_SDL2}
uses CRT;

const
  logFilename = 'LOG.TXT';
var
  logFile: Text;
  logOpened: boolean;
{$endif}


{$ifdef P92_WASM}
procedure WriteLog(const msg: string);
begin
  WriteInteropString(msg);
  FlushLog
end;
{$endif}

{$ifdef P92_SDL2}
procedure InitLogger;
begin
  assign(logFile, logFilename);
  {$I-}
  rewrite(logFile);
  {$I+}
  logOpened := (IOResult = 0);
  if not logOpened then begin
    writeLn('Failed to create "' + logFilename + '" file!');
    readLn;
    halt
  end;
end;

procedure CloseLogger;
begin
  if logOpened then
    close(logFile);
end;

procedure WriteLog(const msg: string);
begin
  textColor(white);
  writeln(msg);

  if not logOpened then exit;
  writeln(logFile, msg);
  flush(logFile)
end;

procedure WriteLogI32(const value: longint);
begin
  textColor(lightMagenta);
  writeln(value);

  if not logOpened then exit;
  writeln(logFile, value);
  flush(logFile)
end;

procedure WriteLogF32(const value: double);
begin
  textColor(lightMagenta);
  writeln(value);

  if not logOpened then exit;
  writeln(logFile, value);
  flush(logFile)
end;

procedure WriteWarn(const msg: string);
begin
  textColor(yellow);
  writeln(msg);

  if not logOpened then exit;
  writeln(logFile, msg);
  flush(logFile)
end;
{$endif}


end.
