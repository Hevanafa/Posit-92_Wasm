{
  Logger - Part of Posit-92 game engine
  Hevanafa

  Trimmed down version of LOGGER.PAS from Posit-92
}

unit Logger;

{$Mode ObjFPC}
{$H-}{$J-}

interface

{$ifdef WASM}
{ Must be registered in importObject }
procedure WriteLogI32(const value: longint); external 'env' name 'WriteLogI32';
procedure WriteLogF32(const value: double); external 'env' name 'WriteLogF32';

function GetLogBuffer: pointer; public name 'GetLogBuffer';
{ Forwards logBuffer to JS }
procedure FlushLog; external 'env' name 'FlushLog';
{$endif}

{$ifdef Windows}
procedure initLogger;
procedure closeLogger;

procedure writeLogI32(const value: longint);
procedure writeLogF32(const value: double);
procedure writeWarn(const msg: string);
{$endif}

procedure writeLog(const msg: string);


implementation

{$ifdef WASM}
var
  logBuffer: array[0..255] of byte;
{$endif}

{$ifdef Windows}
uses CRT;

const
  logFilename = 'LOG.TXT';
var
  logFile: Text;
  logOpened: boolean;
{$endif}

function GetLogBuffer: pointer;
begin
{$ifdef WASM}
  GetLogBuffer := @logBuffer
{$else}
  getLogBuffer := nil
{$endif}
end;


{$ifdef WASM}
procedure writeLog(const msg: string);
var
  a: byte;
  len: word;
begin
  len := length(msg);

  { Cap length to 255 }
  if len > 255 then len := 255;

  logBuffer[0] := len;
  for a:=1 to len do
    logBuffer[a] := ord(msg[a]);

  { JS will read logBuffer }
  FlushLog
end;
{$endif}

{$ifdef Windows}
procedure initLogger;
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

procedure closeLogger;
begin
  if logOpened then
    close(logFile);
end;

procedure writeLog(const msg: string);
begin
  textColor(white);
  writeln(msg);

  if not logOpened then exit;
  writeln(logFile, msg);
  flush(logFile)
end;

procedure writeLogI32(const value: longint);
begin
  textColor(lightMagenta);
  writeln(value);

  if not logOpened then exit;
  writeln(logFile, value);
  flush(logFile)
end;

procedure writeLogF32(const value: double);
begin
  textColor(lightMagenta);
  writeln(value);

  if not logOpened then exit;
  writeln(logFile, value);
  flush(logFile)
end;

procedure writeWarn(const msg: string);
begin
  textColor(yellow);
  writeln(msg);

  if not logOpened then exit;
  writeln(logFile, msg);
  flush(logFile)
end;
{$endif}


end.
